# frozen_string_literal: true

require 'English'
require 'csv'
require 'open3'
require 'shellwords'
require 'active_support/core_ext/hash/keys'
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

  def self.reinitialize!
    remove_const :CONFIG if self.const_defined? :CONFIG
    remove_const :AF_CONFIG if self.const_defined? :AF_CONFIG
    remove_const :PROJECT_BASE if self.const_defined? :PROJECT_BASE

    const_set :CONFIG, load_config('config/active_learning.yml')
    const_set :AF_CONFIG, load_config('config/agentformer.yml')
    const_set :PROJECT_BASE, Snapshot.make_snapshot(CONFIG['active_learning_keras_base'])

    private_constant :CONFIG, :AF_CONFIG, :PROJECT_BASE
  end

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
      out, = Open3.capture2(env_patch, cmd, chdir: PROJECT_BASE)
      out
    else
      pid = spawn(env_patch, cmd, chdir: PROJECT_BASE)
      Process.wait(pid)
      raise "Subprogram exited with error code #{$CHILD_STATUS.exitstatus}" unless $CHILD_STATUS&.success?
    end
  end

  def self.working_dir
    if CONFIG['with_agentformer']
      agentformer_result_dir = AgentFormer.const_get(:CONFIG)['result_dir']
      agentformer_base_dir = Snapshot.make_snapshot(agentformer_result_dir, copy: false)
      agentformer_model_yaml = AgentFormer.renderer_instance.render('agentformer')
      agentformer_model_dir = YAML.safe_load(agentformer_model_yaml)['as']
      File.join(agentformer_base_dir, agentformer_model_dir, 'latents')
    else
      StorageLoader.get_absolute_path CONFIG['working_directory']
    end
  end

  def self.fill_keras_cfg(ext_configs = {})
    # now Agentformer handles configuration
    ftarget = File.join(working_dir, 'model.yml')
    configs = YAML.safe_load(File.read(ftarget))
    # puts ext_configs into config
    configs.merge!(ext_configs)
    configs.stringify_keys!
    File.write(ftarget, YAML.dump(configs))
  end

  ##
  # Train the model
  # @param [Hash] ext_configs
  # @option ext_configs [String] :epochs
  # @option ext_configs [String] :batch_size
  # @return [void]
  def self.keras_train(...)
    fill_keras_cfg(...)

    cmd = CONFIG['python_path'].shellsplit
    cmd << 'keras_train.py'
    cmd << working_dir

    keras_exec cmd.shelljoin
  end

  ##
  # Generate a set of samples
  # @param [Hash] options
  # @option options [String] :dummy (false) If true, generate random samples from uniform distribution
  # @option options [String] :noparse
  # @option options [String] :with_label Required unless :noparse is true
  # @option options [String] :sample_amount
  # @return [String, nil]
  def self.keras_sample_train(**options)
    with_label = options.delete(:with_label)
    dummy = options.delete(:dummy) || false
    noparse = options.delete(:noparse) || false
    sample_amount = options.delete(:count) || CONFIG['sample_amount']['train']

    fill_keras_cfg(options)

    cmd = CONFIG['python_path'].shellsplit
    cmd << 'keras_sampl.py'
    cmd << working_dir
    cmd << '-c' << sample_amount
    cmd << '--parsable'

    samples = keras_exec(cmd.shelljoin, capture: true)
    return samples if noparse

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
    end; nil
  end

  reinitialize!
end
