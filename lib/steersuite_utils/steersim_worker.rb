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
    Semaphore = Mutex.new

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

      Semaphore.synchronize do
        if simulated
          SteerSuite.document(parameter_obj, simulated)
          BenchmarkLogs.new(parameter_object: parameter_obj, log: benchmark_log).save!
        else
          parameter_obj.state = :rot
          parameter_obj.file = "INVALID"
          parameter_obj.save!
        end
      end
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

      simulated = ''
      options = { chdir: workdir }
      options[5] = benchmark_pipe if benchmark_pipe
      Open3.popen2e(env_patch, command, **options) do |i, o, _|
        benchmark_pipe&.close
        i.puts(doc)
        if $DEBUG
          logs = o.readlines
          puts '=================='
          puts logs
          ret = logs.slice_after { |l| l == "Finished scenario 0\n" }.to_a.at(1)
          o = StringIO.new(ret.join)
        else
          o.expect("Finished scenario 0\n")
        end
        simulated = o.gets&.chomp
      end

      simulated
    end

    def simulate_unsimulated
      FileUtils.mkdir_p(StorageLoader.get_path(CONFIG['steersuite_record_pool']))
      unsimulated = ParameterObject.with_no_simulation
      puts "Going to simulate #{unsimulated.size} scenarios"
      Parallel.each(unsimulated, in_threads: `nproc`.to_i) do |pobj|
        SteerSuite.simulate(pobj)
        print '.'
      end
    end

    ##
    # Associate a parameter object to corresponding simulated binary
    # parameter may be changed during simulation due to float error
    def document(pobj, filename)
      data = SteerSuite.load(filename, need_trajectory: false)
      pobj.file = File.absolute_path(filename)
      pobj.safe_set_parameter(data.parameter)
      pobj.save!
    end
  end
end
