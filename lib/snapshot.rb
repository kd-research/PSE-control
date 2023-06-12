# frozen_string_literal: true
require 'tmpdir'
require 'tempfile'
require 'fileutils'
require 'securerandom'
require_relative 'storage_loader'

module Snapshot

  module_function
  def reinitialize!
    set_snapshot_base(File.join(StorageLoader.storage_base, 'snapshots'))
  end

  def set_snapshot_base(path)
    if const_defined?(:SNAPSHOT_PATH)
      Dir.rmdir(SNAPSHOT_PATH) if Dir.empty?(SNAPSHOT_PATH)
      remove_const(:SNAPSHOT_PATH)
    end
    FileUtils.mkdir_p(path)
    pp snpath = Dir.mktmpdir(%w[activeloop- .snapshot], path)
    const_set(:SNAPSHOT_PATH, snpath)
  end

  def make_empty_snapshot(path)
    target = make_snapshot(path, copy: false)
    FileUtils.mkdir_p(target)
    target
  end

  def make_temp_file_in_snapshot(content, prefix: 'activeloop-tmpfile', suffix: nil)
    FileUtils.mkdir_p(File.join(SNAPSHOT_PATH, 'tmp'))
    file = Tempfile.new([prefix, suffix], File.join(SNAPSHOT_PATH, 'tmp'))
    file.write(content)
    file.close
    file.path
  end

  def make_snapshot(path, copy: !$NOINIT)
    basename = File.basename(path)
    target = File.join(SNAPSHOT_PATH, basename)
    FileUtils.cp_r(path, SNAPSHOT_PATH) if copy
    target
  end

  reinitialize!
end
