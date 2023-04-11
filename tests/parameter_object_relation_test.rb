# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../lib/parameter_object'



ParameterDatabase.establish_connection(target: :test)
class ParameterObjectRelationTest < Minitest::Test
  def setup
    ParameterDatabase.initialize_database(force: true)
    seed
  end

  def seed
    3.times do |i|
      ParameterObject.new.save!
    end
  end

  def test_parameter_relation
    a = ParameterObject.find(1)
    b = ParameterObject.find(2)
    c = ParameterObject.find(3)

    ParameterObjectRelation.new do |x|
      x.from = a
      x.to = b
      x.relation = :prediction
    end.save!

    ParameterObjectRelation.new do |x|
      x.from = a
      x.to = c
      x.relation = :augmentation
    end.save!

    assert_equal a.predicted_as.to_a, [b]
    assert_equal b.predicted_from, a
    assert_nil c.predicted_from
  end
end
