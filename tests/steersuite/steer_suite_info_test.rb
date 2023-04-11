# frozen_string_literal: true

require_relative '../test_helper'

# noinspection RubyNilAnalysis
class SteerSuiteInfoTest < Minitest::Test
  def setup
    SteerSuite.reinitialize!
  end

  def test_initialize
    assert_equal 9, SteerSuite::SteersimSceneInfo.new('scene1').parameter_size
    assert_equal 21, SteerSuite::SteersimSceneInfo.new('scene2').parameter_size
    assert_equal 15, SteerSuite::SteersimSceneInfo.new('scene3').parameter_size
    assert_equal 19, SteerSuite::SteersimSceneInfo.new('scene4').parameter_size
  end

  def test_steer_sim_config
    SteerSuite::SteersimSceneInfo.new('scene1').prepare_steer_sim_config!
    assert_match(/sceneBasic1/, SteerSuite.const_get('SteersimConfig').to_xml)

    SteerSuite::SteersimSceneInfo.new('scene2').prepare_steer_sim_config!
    assert_match(/sceneBasic2/, SteerSuite.const_get('SteersimConfig').to_xml)
  end

  def test_set_info
    SteerSuite.set_info('scene1')
    assert_equal 9, SteerSuite.info.parameter_size
    assert_equal 'sceneBasic1', SteerSuite.const_get('SteersimConfig').css('#scene-type').first.name
  end

  def test_data_location
    (1..4).each { |i| verify_data_location("scene#{i}") }
  end

  def test_incorrect_scene
    assert_raises ArgumentError do
      SteerSuite.set_info('scene-not-exist')
    end
  end

  private
  def verify_data_location(scene)
    SteerSuite.set_info(scene)
    data_location = SteerSuite.info.data_location
    assert File.directory?(data_location[:train])
    assert File.directory?(data_location[:valid])
    #assert File.directory?(data_location[:test])
  end
end
