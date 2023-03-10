# frozen_string_literal: true
require 'tmpdir'
require 'fileutils'

module Snapshot
  SNAPSHOT_PATH = Dir.mktmpdir(%w[activeloop- .snapshot])

  module_function

  def make_snapshot(path)
    basename = File.basename(path)
    target = File.join(SNAPSHOT_PATH, basename)
    FileUtils.cp_r(path, target)
    target
  end

  at_exit { FileUtils.rm_rf(SNAPSHOT_PATH) }

end
