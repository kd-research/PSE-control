# frozen_string_literal: true

require 'English'
require 'minitest/autorun'
require_relative 'test_asset'
require_relative '../lib/rplot'
require_relative '../lib/steer_suite'
class RPlotTest < Minitest::Test
  def setup
    super
    @scenario_list = []
    @scenario_list << SteerSuite::Scenario.from_file(
      TestAsset.get_path('steersim_binary/steersim_binary_sample1.bin'))
    @scenario_list << SteerSuite::Scenario.from_file(
      TestAsset.get_path('steersim_binary/steersim_binary_sample2.bin'))

    @keep_tmp_file = false
    @tmpfile = nil
  end

  def need_tmpfile
    @tmpfile = Tempfile.new %w[rplot. .png]
    @tmpfile.close
  end

  def teardown
    @tmpfile&.close! unless @keep_tmp_file
  end

  def wait_plot_succeed(rplot_script:)
    Process.wait
    assert_equal 0, $CHILD_STATUS.exitstatus, <<~ERRORLOG.chomp
      Script executed failed
      #{rplot_script.each_line.map { |x| "> #{x}" }.join}
    ERRORLOG
  end

  def test_named_scenario
    need_tmpfile

    p = RPlot::PlotExecutor.new
    p.plot_scenarios(@scenario_list, as: %w[truth predict])
    p.noninteractive
    p.save_png(@tmpfile.path)
    p.execute

    wait_plot_succeed(rplot_script: p.get_rscript)

    truth = File.read(TestAsset.get_path("images/test_named_scenario_result.png"))
    generated = File.read(@tmpfile.path)
    assert truth == generated
  end

  def test_multi_scenario_plot
    need_tmpfile

    p = RPlot::PlotExecutor.new
    p.plot_scenarios(@scenario_list)
    p.noninteractive
    p.save_png(@tmpfile.path)
    p.execute

    wait_plot_succeed(rplot_script: p.get_rscript)

    truth = File.read(TestAsset.get_path("images/test_multi_scenario_plot_result.png"))
    generated = File.read(@tmpfile.path)
    assert truth == generated
  end

  def test_view_and_save
    need_tmpfile

    p = RPlot::PlotExecutor.new
    p.plot_scenarios(@scenario_list)
    p.interactive(2)
    p.save_png(@tmpfile.path)
    p.execute

    wait_plot_succeed(rplot_script: p.get_rscript)

    truth = File.read(TestAsset.get_path("images/test_view_and_save_result.png"))
    generated = File.read(@tmpfile.path)
    assert truth == generated
  end

  def test_view
    p = RPlot::PlotExecutor.new
    p.interactive(2)
    p.plot_scenarios(@scenario_list)
    p.execute

    plot_action = p.instance_variable_get(:@plot_action)
    assert File.exist?(plot_action.csv_name)
    assert File.size(plot_action.csv_name) > 1

    wait_plot_succeed(rplot_script: p.get_rscript)
  end
end
