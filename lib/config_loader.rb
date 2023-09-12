# frozen_string_literal: true

require "yaml"
require "erb"

module ConfigLoader # :nodoc:
  private

  def load_config(path)
    loaded = YAML.safe_load(ERB.new(File.read(path), trim_mode: "%<>").result, aliases: true)
    userspec = loaded.delete("userspec")
    loaded.except("userspec").merge(userspec[ENV["USER"]] || {})
  end
end
