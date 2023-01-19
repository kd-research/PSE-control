# frozen_string_literal: true
require 'forwardable'

module SteerSuite
  module Data
    class NestedData
      extend Forwardable
      def_delegator :@elements, :size
      attr_reader :elements

      def initialize(elements=nil)
        if block_given?
          @elements = yield
        else
          @elements = elements
        end
      end
    end
  end
end