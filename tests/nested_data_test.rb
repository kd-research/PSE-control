# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../lib/steersuite_utils/trajectory_list'

class NestedDataTest < Minitest::Test
  def test_equal
    t1 = SteerSuite::Data::TrajectoryList.new([0, 0])
    t2 = SteerSuite::Data::TrajectoryList.new([0, 0])

    assert_equal(t1, t2)
  end
end
