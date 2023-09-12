# frozen_string_literal: true

require_relative "../test_helper"
require "ostruct"

class SteersimWorkerTest < Minitest::Test
  def setup
    SteerSuite.reinitialize!
  end

  def test_steersim_worker_dry_run
    pobj = Minitest::Mock.new
    pobj.expect(:to_txt, "1 1 1 1 1 1 1 1 1")
    SteerSuite.simulate(pobj, dry_run: true)
  end

  def have_pobj_mocked
    pobj = Minitest::Mock.new
    pobj.expect(:to_txt, "1 1 1 1 1 1 1 1 1")
    pobj.expect(:safe_set_parameter, nil, [Array])
    pobj.expect(:file=, nil, [String])
    pobj.expect(:save!, nil)
    pobj
  end

  def test_steersim_worker_run_with_debug
    $DEBUG = true
    Dir.mktmpdir do |dir|
      pobj = have_pobj_mocked
      SteerSuite.const_get(:CONFIG).store("steersuite_record_pool", dir)
      BenchmarkLogs.stub(:new, ->(opts) {
        assert opts[:log].length > 0
        Minitest::Mock.new.expect(:save!, nil)
      }) do
        SteerSuite.simulate(pobj)
      end
    end
  ensure
    $DEBUG = false
  end

  def test_steersim_worker_run_without_debug
    Dir.mktmpdir do |dir|
      pobj = have_pobj_mocked
      SteerSuite.const_get(:CONFIG).store("steersuite_record_pool", dir)
      BenchmarkLogs.stub(:new, ->(opts) {
        assert opts[:log].length > 0
        Minitest::Mock.new.expect(:save!, nil)
      }) do
        SteerSuite.simulate(pobj)
      end
    end
  end

  def test_steersim_worker_run_core
    Dir.mktmpdir do |dir|
      SteerSuite.const_get(:CONFIG).store("steersuite_record_pool", dir)
      file = SteerSuite.exec_simulate("1 1 1 1 1 1 1 1 1")
      assert(file && File.exist?(file))
    end
  end

  def test_steersim_worker_verify_scene_change
    SteerSuite.set_info("scene2")
    dry_hash = {}
    SteerSuite.simulate(Minitest::Mock.new.expect(:to_txt, ""), dry_run: true, dry_hash: dry_hash)
    assert_equal dry_hash[:input], ""
    assert_match(/sceneBasic2/, dry_hash[:config])
  end

  def test_steersim_worker_run_core_with_scene_changed
    Dir.mktmpdir do |dir|
      SteerSuite.const_get(:CONFIG).store("steersuite_record_pool", dir)
      SteerSuite.set_info("scene2")
      file = SteerSuite.exec_simulate (["1"] * 21).join(" ")
      assert(file && File.exist?(file))
    end
  end
end
