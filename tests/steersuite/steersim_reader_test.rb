# frozen_string_literal: true

require_relative '../test_helper'
require 'stringio'

class SteersimReaderTest < MiniTest::Test
  def setup
    @ss_struct_data = SteerSuite::Data::SteersimBinary.new.tap do |s|
      s.filename = nil
      s.object_type = [0]
      s.object_info = [0.0]
      s.parameter = [0.0]
      s.agent_data = []
      s.agent_data << SteerSuite::Data::TrajectoryList.new([Vector[0.0, 0.0], Vector[0.0, 0.0]])
      s.agent_data << SteerSuite::Data::TrajectoryList.new([Vector[0.0, 0.0], Vector[0.0, 0.0]])
    end.freeze
    @ss_binary_data = TestAsset.load('steersim_binary/steersuite_binary_dummy.bin')
  end
  def test_writing_correctness
    buf = StringIO.new
    SteerSuite::SteersimBinaryHandler.new(buf, @ss_struct_data).writebin
    assert_equal(@ss_binary_data, buf.string)
  end

  def test_reading_correctness
    buf = StringIO.new(@ss_binary_data)
    struct_data = SteerSuite::SteersimBinaryHandler.new(buf).readbin
    assert_equal(@ss_struct_data, struct_data)
  end

end