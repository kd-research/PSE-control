# frozen_string_literal: true

require 'active_record'
require_relative "../test_helper"

ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: "#{Dir.mktmpdir}/test.sqlite3")

CURRENT_STEERSUITE_SCENE_MAX = 10
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

  (1..CURRENT_STEERSUITE_SCENE_MAX).each do |scenenum|
    scene = "scene#{scenenum}"
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

  it "should work with evac scenario" do
    SteerSuite.set_info("scene_evac_orca")

    10.times do
      p = ParameterObject.new(label: 'budget-ground', split: :train, state: :raw, file: nil)
      p.safe_set_parameter(SteerSuite.info.parameter_size.times.map { rand })
      p.save!
    end

    SteerSuite.simulate_unsimulated

    assert_equal(0, ParameterObject.with_no_simulation.count)
    assert BenchmarkLogs.any?
    assert SteerSuite.unprocessed.any?

  end

  it "should work with evac scenario sf" do
    SteerSuite.set_info("scene_evac_sf")

    10.times do
      p = ParameterObject.new(label: 'budget-ground', split: :train, state: :raw, file: nil)
      p.safe_set_parameter(SteerSuite.info.parameter_size.times.map { rand })
      p.save!
    end

    SteerSuite.simulate_unsimulated

    assert_equal(0, ParameterObject.with_no_simulation.count)
    assert BenchmarkLogs.any?
    assert SteerSuite.unprocessed.any?

  end

  scene_not_exist = "sceneBasic#{CURRENT_STEERSUITE_SCENE_MAX+1}"
  it "won't work with #{scene_not_exist}" do
    SteerSuite::SteersimConfigEditor.change_scene(scene_not_exist)

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
