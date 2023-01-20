# frozen_string_literal: true
require 'forwardable'

module SteerSuite
  module Data
    class NestedData
      extend Forwardable
      def_delegator :@elements, :size
      attr_reader :elements

      def initialize(elements = nil)
        @elements = if block_given?
                      yield
                    else
                      elements
                    end
      end
    end
  end
end