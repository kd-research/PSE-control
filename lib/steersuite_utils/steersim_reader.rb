# frozen_string_literal: true

require "matrix"
require_relative "trajectory_list"
require_relative "steersim_binary_handler"

module SteerSuite
  module SteerSuiteReaderHelper
    def load(filename, need_trajectory: true)
      SteersimBinaryHandler.new(File.open(filename, "rb")).readbin(need_trajectory: need_trajectory)
    rescue => e
      raise StandardError, "Error loading #{filename.inspect}: #{e}"
    end

    def dump(filename, data)
      SteersimBinaryHandler.new(File.open(filename, "wb"), data).writebin
    end

    def load_scenario(filename)
      Scenario.new(load(filename))
    end
  end
end
