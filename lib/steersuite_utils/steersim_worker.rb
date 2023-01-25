# frozen_string_literal: true

require 'yaml'
require 'open3'
require 'expect'

require_relative '../storage_loader'
require_relative '../parameter_object'
require_relative '../steer_suite'

module SteerSuite
  module SteerSuiteWorkerHelper
    ##
    # Simulate a record with no simulation attached
    # return a new record with simulation performed
    def simulate(parameter_obj, dry_run: false)
      env_patch = { 'SteersimRecordPath' => StorageLoader.get_absolute_path(CONFIG['steersuite_record_pool']) }
      command = CONFIG['steersuite_exec_cmd']
      workdir = CONFIG['steersuite_exec_base']

      if dry_run
        return {env_patch: env_patch, command: command, chdir: workdir}
      end
      simulated = ''
      Open3.popen2e(env_patch, command, chdir: workdir) do |i, o, w|
        i.puts(parameter_obj.to_txt)
        o.expect("Finished scenario 0\n")
        simulated = o.gets.chomp
      end
      SteerSuite.document(parameter_obj, simulated)
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