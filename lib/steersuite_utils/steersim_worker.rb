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
    ##
    # Simulate a record with no simulation attached
    # return a new record with simulation performed
    def simulate(parameter_obj, dry_run: false)
      steersim_record_path = StorageLoader.get_absolute_path(CONFIG['steersuite_record_pool'])
      ld_library_path_arr = ENV['LD_LIBRARY_PATH']&.split(':') || []
      ld_library_path_arr << File.join(CONFIG['steersuite_exec_base'], '..', 'lib')
      ld_library_path_arr << File.join(CONFIG['steersuite_exec_base'], 'lib')
      ld_library_path = ld_library_path_arr.join(':')
      env_patch = {
        'SteersimRecordPath' => steersim_record_path,
        'LD_LIBRARY_PATH' => ld_library_path
      }
      command = CONFIG['steersuite_exec_cmd']
      workdir = CONFIG['steersuite_exec_base']

      return { env_patch: env_patch, command: command, chdir: workdir } if dry_run

      simulated = ''
      Open3.popen2e(env_patch, command, chdir: workdir) do |i, o, _|
        i.puts(parameter_obj.to_txt)
        o.expect("Finished scenario 0\n")
        simulated = o.gets.chomp
      end
      SteerSuite.document(parameter_obj, simulated)
    end

    def simulate_unsimulated
      FileUtils.mkdir_p(StorageLoader.get_path(CONFIG['steersuite_record_pool']))
      unsimulated = ParameterObject.with_no_simulation
      puts "Going to simulate #{unsimulated.size} scenarios"
      Parallel.each(unsimulated) do |pobj|
        SteerSuite.simulate(pobj)
        print '.'
      end
    end

    ##
    # Associate a parameter object to corresponding simulated binary
    # parameter may be changed during simulation due to float error
    def document(pobj, filename)
      data = SteerSuite.load(filename, need_trajectory: false)
      pobj.file = filename
      pobj.safe_set_parameter(data.parameter)
      pobj.save!
    end
  end
end
