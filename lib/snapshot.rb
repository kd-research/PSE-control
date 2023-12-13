# frozen_string_literal: true

require "tmpdir"
require "tempfile"
require "fileutils"
require "securerandom"
require_relative "storage_loader"

module Snapshot
  module_function

  def reinitialize!
    set_snapshot_base(File.join(StorageLoader.storage_base, "snapshots"))
    @reusing_snapshot = false
  end

  def reuse_snapshot!(path)
    if const_defined?(:SNAPSHOT_PATH)
      Dir.rmdir(SNAPSHOT_PATH) if Dir.empty?(SNAPSHOT_PATH)
      remove_const(:SNAPSHOT_PATH)
    end

    const_set(:SNAPSHOT_PATH, path)
    puts "Reusing snapshot #{path}"
    @reusing_snapshot = true
  end

  def set_snapshot_base(path)
    if const_defined?(:SNAPSHOT_PATH)
      Dir.rmdir(SNAPSHOT_PATH) if Dir.empty?(SNAPSHOT_PATH)
      remove_const(:SNAPSHOT_PATH)
    end
    FileUtils.mkdir_p(path)
    snpath = Dir.mktmpdir(%w[activeloop- .snapshot], path)
    puts "Initialized snapshot path: #{snpath}"
    const_set(:SNAPSHOT_PATH, snpath)
  end

  def make_empty_snapshot(path)
    target = make_snapshot(path, copy: false)
    FileUtils.mkdir_p(target)
    target
  end

  def make_temp_file_in_snapshot(content, prefix: "activeloop-tmpfile", suffix: nil)
    FileUtils.mkdir_p(File.join(SNAPSHOT_PATH, "tmp"))
    file = Tempfile.new([prefix, suffix], File.join(SNAPSHOT_PATH, "tmp"))
    file.write(content)
    file.close
    file.path
  end

  def make_snapshot(path, copy: !$NOINIT)
    basename = File.basename(path)
    target = File.join(SNAPSHOT_PATH, basename)
    if File.exist?(target) && !@reusing_snapshot
      warn "Snapshot #{basename} already exists, not overwriting."
    else
      FileUtils.cp_r(path, SNAPSHOT_PATH) if copy
    end
    target
  end

  def recover_snapshot_from(path)
    make_snapshot("#{path}/agentformer-result")
  end

  reinitialize!
end
