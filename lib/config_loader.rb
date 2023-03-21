# frozen_string_literal: true
require 'yaml'
require 'erb'

module ConfigLoader
  private
  def load_config(path)
    YAML.safe_load(ERB.new(File.read(path), trim_mode: '%<>').result, aliases: true)
  end
end
