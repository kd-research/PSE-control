# frozen_string_literal: true

require 'forwardable'
require_relative '../steer_suite'
require_relative 'data_struct'
require_relative 'steersim_worker'

module SteerSuite
  module Data
    SteersimBinary = Struct.new(:filename, :object_type, :object_info, :parameter, :agent_data)
  end
  class Scenario < Data::NestedData
    extend Forwardable
    def_delegators :@elements, *Data::SteersimBinary.members

    def self.from_file(filename)
      new(SteerSuite.load(filename, need_trajectory: true))
    end

    def map_trajectory(&block)
      return enum_for(:map_trajectory) unless block_given?

      new_agent_data = agent_data.map(&block)
      return nil unless new_agent_data.all?

      new_elem = @elements.clone
      new_elem.agent_data = new_agent_data
      Scenario.new(new_elem)
    end

    def to_file(dirname)
      filename = File.join(dirname, "#{@elements.filename}.bin")
      SteerSuite.dump(filename, @elements)
      filename
    end

    def inspect
      "#<Scenario agent_data=#{agent_data.inspect}>"
    end
  end
end
