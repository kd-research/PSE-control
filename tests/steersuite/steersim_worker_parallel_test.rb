# frozen_string_literal: true

require 'active_record'
require_relative "../test_helper"

ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: "#{Dir.mktmpdir}/test.sqlite3")

describe SteerSuite::SteerSuiteWorkerHelper do
  before do
    SteerSuite.reinitialize!
    ParameterDatabase.initialize_database(force: true)
  end

  it 'should work in parallel' do
    simulate_sample_1 = TestAsset.get_path('steersim_binary/sample1.bin')
    SteerSuite.stub(:simulate,
                    lambda do |_pobj, **_opts|
                      sleep(rand(0.1))
                      { filename: simulate_sample_1, benchmark_log: Random.alphanumeric(100) }
                    end
    ) do
      SteerSuite.set_info('scene1')
      100.times do
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
    it "should work with #{scene}" do
      SteerSuite.set_info(scene)

      refute SteerSuite.unprocessed.any?, 'There should be no unprocessed parameter objects'

      10.times do
        p = ParameterObject.new(label: 'budget-ground', split: :train, state: :raw, file: nil)
        p.safe_set_parameter(SteerSuite.info.parameter_size.times.map { rand })
        p.save!
      end

      SteerSuite.simulate_unsimulated

      assert_equal(0, ParameterObject.with_no_simulation.count)
      assert BenchmarkLogs.any?
      assert SteerSuite.unprocessed.any?

      SteerSuite.process_unprocessed
      assert ParameterObject.processed.any?
    end
  end

  it "won't work with scene5" do
    SteerSuite::SteersimConfigEditor.change_scene('sceneBasic5')

    10.times do
      p = ParameterObject.new(label: 'budget-ground', split: :train, state: :raw, file: nil)
      p.safe_set_parameter(9.times.map { rand })
      p.save!
    end

    SteerSuite.simulate_unsimulated

    assert_equal(0, BenchmarkLogs.count)
    assert_equal(10, ParameterObject.rot.count)
  end
end
