# frozen_string_literal: true

require 'English'
require 'csv'
require 'open3'
require 'shellwords'
require_relative '../snapshot'
require_relative '../config_loader'
require_relative '../agent_former'
require_relative '../parameter_object'

##
# step 1:
# Get a set of random parameter
# Call Steersim to generate a set of binaries
# Implemented in Task['steersuite:auto-simulate']
#
# step 2:
# Train AgentFormer
module ActiveLearningCaller
  extend ConfigLoader
  CONFIG = load_config('config/active_learning.yml')
  AF_CONFIG = load_config('config/agentformer.yml')
  PROJECT_BASE = Snapshot.make_snapshot(CONFIG['active_learning_keras_base'])
  private_constant :CONFIG, :AF_CONFIG, :PROJECT_BASE
  ##
  # Active learning model require an arg as working directory,
  # and PYTHON_PATH set to the code base.
  # needs training/validating dataset inside working dirertory
  # and will save training weights in the same directory under
  # best_valid checkpoint file
  def self.keras_exec(cmd, capture: false)
    env_patch = {
      'PYTHON_PATH' => "#{ENV['PYTHON_PATH']}:#{PROJECT_BASE}"
    }
    if capture
      out, _ = Open3.capture2(env_patch, cmd, chdir: PROJECT_BASE)
      out
    else
      pid = spawn(env_patch, cmd, chdir: PROJECT_BASE)
      Process.wait(pid)
      raise "Subprogram exited with error code #{$CHILD_STATUS.exitstatus}" unless $CHILD_STATUS&.success?
    end

  end

  def self.working_dir
    if CONFIG['with_agentformer']
      agentformer_base_dir = StorageLoader.get_absolute_path AF_CONFIG['result_dir']
      agentformer_model_yaml = AgentFormer.renderer_instance.render('agentformer')
      agentformer_model_dir = YAML.safe_load(agentformer_model_yaml)['as']
      File.join(agentformer_base_dir, agentformer_model_dir, 'latents')
    else
      StorageLoader.get_absolute_path CONFIG['working_directory']
    end
  end

  def self.fill_keras_cfg
    File.write File.join(working_dir, "model.cfg"), <<~CONFIG
      parameter_size = #{SteerSuite.info.parameter_size}
    CONFIG
  end

  def self.keras_train(fast: false)
    fill_keras_cfg

    cmd = CONFIG['python_path'].shellsplit
    cmd << 'keras_train.py'
    cmd << working_dir
    cmd << '--fast' if fast

    keras_exec cmd.shelljoin
  end

  def self.keras_sample_train(with_label: nil, dummy: false)
    fill_keras_cfg

    cmd = CONFIG['python_path'].shellsplit
    cmd << 'keras_sampl.py'
    cmd << working_dir
    cmd << '-c' << CONFIG['sample_amount']['train']
    cmd << '--parsable'

    samples = keras_exec(cmd.shelljoin, capture: true)
    CSV.parse(samples, converters: :all).each do |pararmeter|
      # @parameter : An array of size 9
      pararmeter.map! { |x| (x.between?(0, 1) && !dummy) ? x : rand }
      obj = ParameterObject.new
      obj.safe_set_parameter(pararmeter)
      obj.active_generated = true
      obj.split = :train
      obj.state = :raw
      obj.label = with_label
      obj.save!
    end

  end

end
