# frozen_string_literal: true

require_relative 'data_struct'

module SteerSuite
  module Data
    class TrajectoryList < NestedData
      def initialize(elements) # :nodoc:
        super
        @default_speed_proc = ->(x, y) { (x - y).r }
      end

      def speed_proc=(blk) # :nodoc:
        @default_speed_proc = blk
      end

      # Block return new element sit on each frame
      def map_frame
        return to_enum(:each_frame) unless block_given?
        results = @elements.map { |framevec| yield framevec }.compact
        return nil if results.empty?
        TrajectoryList.new(results)
      end

      # Block return new element sit on each frame
      def map_speed(speed_proc=:set_info)
        return to_enum(:each_speed, speed_proc) unless block_given?

        unless speed_proc.respond_to? :call
          case speed_proc
          when :set_info
            speed_proc = @default_speed_proc
          when :identity
            speed_proc = proc { |x, y| [x, y] }
          when :detailed
            speed_proc = proc { |x, y| [@default_speed_proc[x, y], [x, y]] }
          else
            raise "Not a valid speed proc #{speed_proc}"
          end
        end

        results = @elements.each_cons(2).map { |x, y| yield speed_proc[x, y] }.compact
        return nil if results.empty?
        TrajectoryList.new(results)
      end

      alias_method :to_a, :elements

      def rawdata
        @elements.flat_map { |v| v.to_a }
      end

      def inspect
        "#<TrajectoryList size=#{@elements.size}, type=#{@elements.first.class}>"
      end

      def compact
        cpt = @elements.compact
        if cpt.empty?
          nil
        else
          TrajectoryList.new(@elements.compact)
        end
      end

      def ==(other)
        false if other.class != self.class
        elements == other.elements
      end
    end
  end
end
