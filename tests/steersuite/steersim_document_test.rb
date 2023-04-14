# frozen_string_literal: true

require_relative '../test_helper'

ParameterDatabase.establish_connection(target: :test)
class SteersimDocumentTest < Minitest::Test
  def setup
    ParameterObject.initialize_database(force: true)
  end

  def test_if_file_documented
    allsamples = Dir.glob("sample*.bin", base: TestAsset.get_path('steersim_binary'))
    allsamples.each do |sample|
      pobj = ParameterObject.new(label: 'budget-ground', split: :train, state: :raw, file: nil)
      fullname = File.join(TestAsset.get_path('steersim_binary'), sample)
      SteerSuite.document(pobj, fullname)
      pobj.save!
    end

    assert_equal(allsamples, ParameterObject.pluck(:file).map { |f| File.basename(f) })
  end

  def test_if_file_documented_with_keyword_arguments
    allsamples = Dir.glob("sample*.bin", base: TestAsset.get_path('steersim_binary'))
    allsamples.each do |sample|
      pobj = ParameterObject.new(label: 'budget-ground', split: :train, state: :raw, file: nil)
      fullname = File.join(TestAsset.get_path('steersim_binary'), sample)
      SteerSuite.document(pobj, filename: fullname)
      pobj.save!
    end

    assert_equal(allsamples, ParameterObject.pluck(:file).map { |f| File.basename(f) })
  end
end
