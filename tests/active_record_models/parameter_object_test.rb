# frozen_string_literal: true

require_relative "../test_helper"

ParameterDatabase.establish_connection(target: :test)
class ParameterObjectTest < Minitest::Test
  def setup
    ParameterObject.initialize_database(force: true)
  end

  def test_find_record_by_parameter
    3.times do |i|
      parameter_length = rand(10..20)
      50.times do |i|
        pobj = ParameterObject.new(label: "budget-ground", split: :train, state: :raw, file: nil)
        pobj.safe_set_parameter(parameter_length.times.map { rand })
        pobj.save!
      end
    end

    ParameterObject.all.each do |pobj|
      assert_equal(pobj.p_hash, ParameterObject.parameter_hash_func(pobj.parameters))
      assert_equal(pobj, ParameterObject.find_by_parameter(pobj.parameters))
    end
  end
end
