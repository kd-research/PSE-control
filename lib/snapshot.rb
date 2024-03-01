# frozen_string_literal: true

require "tmpdir"
require "tempfile"
require "fileutils"
require "securerandom"
require_relative "strategies"
require_relative "storage_loader"

module Snapshot
  module_function

  def reinitialize!
    set_snapshot_base(File.join(StorageLoader.storage_base, "snapshots"))
    @reusing_snapshot = false
  end

  # Reuse a snapshot from a given path, contents will be modified
  def reuse_snapshot!(path)
    if const_defined?(:SNAPSHOT_PATH)
      abort "Cannot reuse snapshot, already initialized"
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
    File.write(path + "/.last-snapshot-path", snpath)
    const_set(:SNAPSHOT_PATH, snpath)
  end

  def make_empty_snapshot(path, exist_ok: false)
    target = make_snapshot(path, copy: false, exist_ok: exist_ok)
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

  # By default, copy the contents of the path to the snapshot
  # Otherwise
  def make_snapshot(path, copy: true, subpath: nil, exist_ok: false)
    copy = false if STRATEGY::NOINIT

    basename = File.basename(path)
    basename = File.join(subpath, basename) if subpath
    target = File.join(SNAPSHOT_PATH, basename)
    unless File.exist?(target).! || @reusing_snapshot || exist_ok
      warn "From: #{caller(1..1).first}, Snapshot #{basename} already exists"
    end
    FileUtils.mkdir_p(File.dirname(target))
    FileUtils.cp_r(path, target) if copy
    target
  end

  def recover_snapshot_from(path)
    unless path.end_with?("agentformer-result")
      path = File.join(path, "agentformer-result")
    end
    make_snapshot(path)
  end

  reinitialize! unless STRATEGY::NOINIT
end
