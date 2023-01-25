# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../lib/parameter_object'
require_relative '../lib/parameter_object_relation'



ParameterObject.establish_connection(target: :test)
class ParameterObjectRelationTest < Minitest::Test
  def setup
    # ParameterObjectRelation.initialize_database(force: true)
  end

  def test_parameter_relation
    skip("needs database setup")
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
