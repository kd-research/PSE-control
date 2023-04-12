# frozen_string_literal: true

require 'nokogiri'
require_relative 'config_loader'

require_relative 'steersuite_utils/steersim_scene_info'
require_relative 'steersuite_utils/data_struct'
require_relative 'steersuite_utils/scenario'
require_relative 'steersuite_utils/steersim_reader'
require_relative 'steersuite_utils/steersim_worker'
require_relative 'steersuite_utils/steersim_postprocessor'
require_relative 'steersuite_utils/steersim_config_editor'

##
# Main module for steersuite operations

module SteerSuite
  extend ConfigLoader
  extend SteerSuiteWorkerHelper
  extend SteerSuiteReaderHelper
  extend SteersimPostprocessor

  def self.reinitialize!
    remove_const :CONFIG if self.const_defined? :CONFIG
    remove_const :SteersimConfig if self.const_defined? :SteersimConfig
    @info = nil

    const_set :CONFIG, load_config('config/steersuite.yml')
    const_set :SteersimConfig, Nokogiri::XML(File.open(CONFIG['steersuite_config_path']))
    private_constant :CONFIG, :SteersimConfig
  end

  def self.get_config
    CONFIG.dup.freeze
  end

  # @param [String] scene
  # @return [nil]
  def self.set_info(scene)
    unless CONFIG['scene_defs'].include? scene
      raise ArgumentError, "Scene #{scene} not defined in config/steersuite.yml"
    end

    @info = SteersimSceneInfo.new(scene)
    # noinspection RubyNilAnalysis
    @info.prepare_steer_sim_config!
    nil
  end

  # @return [SteersimSceneInfo, nil]
  def self.info
    @info || raise('No scene info set')
  end

  def self.change_scene(*)
    raise 'Deprecated method'
  end

  reinitialize!
end
