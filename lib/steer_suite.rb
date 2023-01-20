# frozen_string_literal: true

require_relative 'steersuite_utils/data_struct'
require_relative 'steersuite_utils/scenario'
require_relative 'steersuite_utils/steersim_reader'
require_relative 'steersuite_utils/steersim_worker'

module SteerSuite
  @config = YAML.safe_load(File.open('config/steersuite.yml'))
  extend SteerSuiteWorkerHelper
  extend SteerSuiteReaderHelper

  #Scenario = Data::Scenario
end
