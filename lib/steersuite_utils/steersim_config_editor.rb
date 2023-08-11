# frozen_string_literal: true

require 'nokogiri'

module SteerSuite
  module SteersimConfigEditor
    def change_scene(scenename)
      new_scene = Nokogiri::XML::Node.new(scenename, SteersimConfig)
      new_scene['id'] = 'scene-type'
      SteersimConfig.at('#scene-type').replace(new_scene)
    end

    def set_ai(ai_type)
      case ai_type
      when 'social-force'
        SteersimConfig.search("spatialDatabase").remove
        SteersimConfig.at("scenarioAI").content = "sfAI"
      end
    end

    module_function :change_scene, :set_ai
  end
end
