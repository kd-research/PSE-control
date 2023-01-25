# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../lib/parameter_object'

ParameterObject.establish_connection(target: :test)
class ParameterObjectTest < Minitest::Test
  def setup
    #ParameterObject.initialize_database(force: true)
  end

  def test_find_record_by_parameter
    skip("Not applicable currently")
    5.times do |i|
      a = ParameterObject.find(i+1)
      result = ParameterObject.find_by_parameter(a.parameters)
      ParameterObject.parameter_hash_func(a.parameters)

      assert_equal(a.p_hash, ParameterObject.parameter_hash_func(a.parameters))
      assert_equal(a, result)
    end
  end
end
