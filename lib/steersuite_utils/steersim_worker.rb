# frozen_string_literal: true

require 'yaml'
require 'open3'
require 'expect'
require 'fileutils'
require 'parallel'

require_relative '../storage_loader'
require_relative '../parameter_object'
require_relative '../steer_suite'

module SteerSuite
  module SteerSuiteWorkerHelper
    class BadSimulationError < StandardError; end
    ##
    # Simulate a record with no simulation attached
    # return a new record with simulation performed
    # @param [ParameterObject] parameter_obj
    # @param [Boolean] dry_run
    # @return [nil]
    def simulate(parameter_obj, dry_run: false, dry_hash: nil)
      return exec_simulate(parameter_obj.to_txt, dry_run: dry_run, dry_hash: dry_hash) if dry_run

      r, w = IO.pipe
      simulated = exec_simulate(parameter_obj.to_txt, benchmark_pipe: w)
      benchmark_log = r.read

      { filename: simulated, benchmark_log: benchmark_log }
    end

    # Take steersim processing a string document and return
    # the path of generated steersim binary record
    # @param [String] doc
    # @param [Boolean] dry_run
    # @param [IO] benchmark_pipe
    # @param [Hash, nil] dry_hash
    def exec_simulate(doc, dry_run: false, benchmark_pipe: nil, dry_hash: nil)
      steersim_record_path = StorageLoader.get_absolute_path(CONFIG['steersuite_record_pool'])
      ld_library_path_arr = ENV['LD_LIBRARY_PATH']&.split(':') || []
      ld_library_path_arr << File.join(CONFIG['steersuite_exec_base'], '..', 'lib')
      ld_library_path_arr << File.join(CONFIG['steersuite_exec_base'], 'lib')
      ld_library_path = ld_library_path_arr.join(':')
      env_patch = {
        'SteersimRecordPath' => steersim_record_path,
        'LD_LIBRARY_PATH' => ld_library_path
      }
      config_path = Snapshot.make_temp_file_in_snapshot(SteersimConfig.to_xml,
                                                        prefix: 'steersuite-config-', suffix: '.xml')
      command = CONFIG['steersuite_exec_cmd'] + " -config #{config_path}"
      workdir = CONFIG['steersuite_exec_base']


      if $DEBUG
        puts "Steersuite record path: #{steersim_record_path}"
        puts "LD_LIBRARY_PATH: #{ld_library_path}"
        puts "Command: #{command}"
        puts "Workdir: #{workdir}"
        puts "Pipe in: #{doc}"
        puts "config content: #{SteersimConfig.to_xml}"
      end

      if dry_run
        dry_hash&.update(
          { input: doc, env_patch: env_patch, command: command, chdir: workdir, config: SteersimConfig.to_xml })
        return nil
      end

      retry_count = 0
      retry_max = 10

      begin

        simulated = nil
        options = { chdir: workdir }
        options[5] = benchmark_pipe if benchmark_pipe
        Open3.popen2e(env_patch, command, **options) do |i, o, w|
          i.puts(doc)
          buffer = o.readlines
          if $DEBUG
            puts '=================='
            puts buffer
          end

          raise BadSimulationError if w.value != 0 && buffer.include?("Corrupted simulator!\n")

          if buffer.include?("Finished scenario 0\n")
            simulated = buffer.slice_after { |l| l == "Finished scenario 0\n" }.to_a.dig(1, 0)&.chomp
          else
            puts "Bad simulation result for #{doc.first(10)}, dump last 3 lines and discard."
            puts(buffer.last(3).map { |l| "[#{doc.first(10)}]: #{l.chomp}" })
          end
        end

      rescue BadSimulationError
        retry_count += 1
        if retry_count <= retry_max
          puts <<~MESSAGE
            Bad simulation result for "#{doc.first(10)}...", retrying (#{retry_count}/#{retry_max})...
          MESSAGE
          retry
        else
          puts %(Bad simulation result for "#{doc.first(10)}...", simulation failed.)
        end
      ensure
        benchmark_pipe&.close
      end

      simulated
    end

    def simulate_unsimulated
      FileUtils.mkdir_p(StorageLoader.get_path(CONFIG['steersuite_record_pool']))
      unsimulated = ParameterObject.with_no_simulation
      puts "Going to simulate #{unsimulated.size} scenarios"
      Parallel.each(unsimulated,
                    in_threads: `nproc`.to_i,
                    finish: lambda { |pobj, _, result|
                               SteerSuite.document(pobj, **result)
                               print '.' if STDOUT.tty?
                             }) do |pobj|
        SteerSuite.simulate(pobj)
      end
      print "\r" if STDOUT.tty?
    end

    ##
    # Associate a parameter object to corresponding simulated binary
    # parameter may be changed during simulation due to float error
    def document(pobj, *args, filename: nil, benchmark_log: nil)
      # second positional argument may be filename
      filename = args.fetch(0, filename)

      ActiveRecord::Base.connection_pool.with_connection do
        unless filename
          puts "Bad simulation result for #{pobj.id}"
          pobj.state = :rot
          pobj.file = "INVALID"
          pobj.save!

          return
        end

        data = SteerSuite.load(filename, need_trajectory: false)
        pobj.file = File.absolute_path(filename)
        pobj.safe_set_parameter(data.parameter)
        pobj.save!
        return unless benchmark_log

        BenchmarkLogs.new(parameter_object: pobj, log: benchmark_log).save!
      end
    end
  end
end
