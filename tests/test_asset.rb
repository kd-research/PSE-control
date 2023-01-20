# frozen_string_literal: true

module TestAsset
  ##
  # Will read asset file relative to tests folder
  def self.load(path, opt={})
    opt_with_default = {mode: 'rb'}.merge(opt)
    target = get_path(path)
    File.read(target, opt: opt_with_default)
  end

  def self.get_path(path)
    File.expand_path("../assets/#{path}", __FILE__)
  end
end
