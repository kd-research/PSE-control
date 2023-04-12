# frozen_string_literal: true

require_relative '../test_helper'

require 'yaml'

class AgentFormerConfigRendererTest < Minitest::Test
  def setup
    @renderer = AgentFormer.renderer_instance
  end
  def test_render_plain
    result = @renderer.render 'vae_spec'
    assert result.size > 1
  end

  def test_render_with_cfg
    result = @renderer.render 'data_global'
    ryaml = YAML.safe_load(result)
    assert AgentFormer.const_get(:CONFIG)['result_dir'], ryaml['results_root_dir']
  end

  def test_render_complex
    result = @renderer.render 'agentformer'
    ryaml = YAML.safe_load(result)
    assert AgentFormer.const_get(:CONFIG)['result_dir'], ryaml['results_root_dir']
  end
end
