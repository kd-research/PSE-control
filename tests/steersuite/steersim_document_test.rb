# frozen_string_literal: true

require_relative '../test_helper'

ParameterDatabase.establish_connection(target: :test)
class SteersimDocumentTest < Minitest::Test
  def setup
    ParameterObject.initialize_database(force: true)
  end

  def test_if_file_documented
    allsamples = Dir.glob("#{TestAsset.get_path('steersim_binary')}/sample*.bin")
    allsamples.each do |sample|
      pobj = ParameterObject.new(label: 'budget-ground', split: :train, state: :raw, file: nil)
      SteerSuite.document(pobj, sample)
      pobj.save!
    end

    assert_equal(allsamples, ParameterObject.pluck(:file))
  end

  def test_if_file_documented_with_keyword_arguments
    allsamples = Dir.glob("#{TestAsset.get_path('steersim_binary')}/sample*.bin")
    allsamples.each do |sample|
      pobj = ParameterObject.new(label: 'budget-ground', split: :train, state: :raw, file: nil)
      SteerSuite.document(pobj, filename: sample)
      pobj.save!
    end

    assert_equal(allsamples, ParameterObject.pluck(:file))
  end
end
