# frozen_string_literal: true

require 'active_record'
require_relative "../test_helper"

ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: "#{Dir.mktmpdir}/test.sqlite3")

class SteersimWorkerParallelTest < Minitest::Test
  def setup
    ParameterDatabase.initialize_database(force: true)
  end

  def test_if_parallel_works
    simulate_sample_1 = TestAsset.get_path('steersim_binary/sample1.bin')
    SteerSuite.stub(:simulate,
                    lambda do |pobj, **opts|
                      sleep(rand(0.1))
                      { filename: simulate_sample_1, benchmark_log: Random.alphanumeric(100) }
                    end
    ) do
      SteerSuite.set_info('scene1')
      100.times do |_i|
        p = ParameterObject.new(label: 'budget-ground', split: :train, state: :raw, file: nil)
        p.safe_set_parameter(9.times.map { rand })
        p.save!
      end
      SteerSuite.simulate_unsimulated
      assert_equal(0, ParameterObject.with_no_simulation.count)
      assert_equal(100, BenchmarkLogs.count)

      SteerSuite.process_unprocessed

      assert_equal(0, ParameterObject.with_no_simulation.count)
    end
  end

  %w[scene1 scene2 scene3 scene4].each do |scene|
    define_method("test_if_auto_simulation_works_with_#{scene}") do
      SteerSuite.set_info('scene1')

      10.times do |i|
        p = ParameterObject.new(label: 'budget-ground', split: :train, state: :raw, file: nil)
        p.safe_set_parameter(SteerSuite.info.parameter_size.times.map { rand })
        p.save!
      end

      SteerSuite.simulate_unsimulated

      amount_unprocessed = ParameterObject.where.missing(:as_processor_relation).and(ParameterObject.raw).count
      assert_equal(0, ParameterObject.with_no_simulation.count)
      assert_equal(10, BenchmarkLogs.count)
      assert_equal(10, amount_unprocessed)

      SteerSuite.process_unprocessed
    end
  end
end
