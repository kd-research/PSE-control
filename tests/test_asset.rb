# frozen_string_literal: true

module TestAsset
  def self.load(path, opt={})
    opt_with_default = {mode: 'rb'}.merge(opt)
    target = File.expand_path("../#{path}", __FILE__)
    File.read(target, opt: opt_with_default)
  end
end
