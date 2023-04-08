# frozen_string_literal: true

require 'nokogiri'

module SteerSuite
  module SteersimConfigEditor
    def change_scene(scenename)
      new_scene = Nokogiri::XML::Node.new(scenename, SteersimConfig)
      new_scene['id'] = 'scene-type'
      SteersimConfig.at('#scene-type').replace(new_scene)
    end
  end
end
