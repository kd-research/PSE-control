# frozen_string_literal: true

require_relative '../test_helper'
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
    SteerSuite::SteersimSceneInfo.new('scene1').prepare_steer_sim_config
    assert_match(/sceneBasic1/, SteerSuite.const_get('SteersimConfig').to_xml)

    SteerSuite::SteersimSceneInfo.new('scene2').prepare_steer_sim_config
    assert_match(/sceneBasic2/, SteerSuite.const_get('SteersimConfig').to_xml)
  end

  def test_set_info
    SteerSuite.default('scene1')
    assert_equal 9, SteerSuite.info.parameter_size
    assert_equal 'sceneBasic1', SteerSuite.const_get('SteersimConfig').css('#scene-type').first.name
  end
end
