# frozen_string_literal: true
require_relative 'trajectory_list'
require_relative '../parameter_object'
module SteerSuite
  module SteersimPostprocessor
    def process_document(raw_doc)
      sobj = raw_doc.as_scenario_obj
      raise 'Not a scenario object' unless sobj.is_a? Scenario
      new_sobj = sobj.map_trajectory do |traj|
        oldelem = traj.elements
        newelem = oldelem.reduce({s:[], a:[oldelem.first]}) do |memo, pos|
          memo[:a] << (memo[:s].last || pos) if (pos-memo[:a].last).r > 0.08
          if (pos-memo[:a].last).r > 0.04
            memo[:a] << pos
            memo[:s] = []
          else
            memo[:s] << pos
          end
          memo
        end

        next nil unless newelem[:a].size <= 135
        next nil unless newelem[:a].size > 50

        compressed = newelem[:a].each_slice(5).map {|arr| arr.first }
        Data::TrajectoryList.new(compressed)
      end

      if new_sobj.nil?
        raw_doc.state = :rot
        raw_doc.save!
      else
        new_fname = new_sobj.to_file StorageLoader.get_path CONFIG['steersuite_process_pool']
        dup = raw_doc.dup
        dup.state = :processed
        SteerSuite.document(dup, new_fname)
        ParameterObjectRelation.new(from: raw_doc, to: dup, relation: :process).save!
      end

      print('.') if $stdout.tty?
    end

    def unprocessed
      ParameterObject.where.missing(:as_processor_relation).and ParameterObject.raw
    end

    def process_unprocessed
      FileUtils.mkdir_p(StorageLoader.get_path(CONFIG['steersuite_process_pool']))
      puts "Going to process #{unprocessed.size} files"
      unprocessed.each(&method(:process_document))
      print("\r") if $stdout.tty?
    end

    def validate_raw
      puts "Going to validate #{ParameterObject.raw.count} files"
      mark_proc = proc do |doc|
        doc.state = if doc.as_scenario_obj.valid?
                      :valid_raw
                    else
                      puts "Bad simulation result for #{doc.file}"
                      :rot
                    end
        doc.save!
      end
      
      if $stdout.tty?
        ParameterObject.raw.tqdm.each(&mark_proc)
        print("\r\n")
      else
        ParameterObject.raw.each(&mark_proc)
      end
    end

  end

end
