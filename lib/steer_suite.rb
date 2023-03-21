# frozen_string_literal: true

require_relative 'config_loader'
require_relative 'steersuite_utils/data_struct'
require_relative 'steersuite_utils/scenario'
require_relative 'steersuite_utils/steersim_reader'
require_relative 'steersuite_utils/steersim_worker'
require_relative 'steersuite_utils/steersim_postprocessor'

##
# Main module for steersuite operations

module SteerSuite
  extend ConfigLoader
  CONFIG = load_config('config/steersuite.yml')
  private_constant :CONFIG
  extend SteerSuiteWorkerHelper
  extend SteerSuiteReaderHelper
  extend SteersimPostprocessor

  #Scenario = Data::Scenario
end
