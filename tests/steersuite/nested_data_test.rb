# frozen_string_literal: true

require_relative '../test_helper'

class NestedDataTest < Minitest::Test
  def test_equal
    t1 = SteerSuite::Data::TrajectoryList.new([0, 0])
    t2 = SteerSuite::Data::TrajectoryList.new([0, 0])

    assert_equal(t1, t2)
  end
end
