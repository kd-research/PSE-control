# frozen_string_literal: true

require 'yaml'
require 'open3'
require 'expect'

class SteersimWorker
  @config = YAML.safe_load(File.open('config/steersuite.yml'))

  def self.simulate(parameter_obj)
    env_patch = { 'SteersimRecordPath' => @config['steersuite_record_pool'] }
    command = @config['steersuite_exec_cmd']
    workdir = @config['steersuite_exec_base']

    Open3.popen2e(env_patch, command, chdir: workdir) do |i, o|
      i.puts(parameter_obj.to_txt)
      o.expect("Finished scenario 0\n")
      parameter_obj.file = o.gets
    end
    parameter_obj.state = :raw
    parameter_obj.save!
  end
end