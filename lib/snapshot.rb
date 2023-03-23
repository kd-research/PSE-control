# frozen_string_literal: true
require 'tmpdir'
require 'fileutils'
require_relative 'storage_loader'

module Snapshot
  SNAPSHOT_PATH = Dir.mktmpdir(%w[activeloop- .snapshot], StorageLoader.storage_base)

  module_function

  def make_snapshot(path, copy: true)
    basename = File.basename(path)
    target = File.join(SNAPSHOT_PATH, basename)
    FileUtils.cp_r(path, target) if copy
    target
  end

end
