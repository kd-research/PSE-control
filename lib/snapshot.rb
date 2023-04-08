# frozen_string_literal: true
require 'tmpdir'
require 'fileutils'
require 'securerandom'
require_relative 'storage_loader'

module Snapshot
  SNAPSHOT_PATH = Dir.mktmpdir(%w[activeloop- .snapshot], StorageLoader.storage_base)

  module_function
  def make_empty_snapshot(path)
    target = make_snapshot(path, copy: false)
    FileUtils.mkdir_p(target)
    target
  end

  def make_temp_file_in_snapshot(content)
    path = File.join(SNAPSHOT_PATH, Random.alphanumeric(10))
    path = File.join(SNAPSHOT_PATH, Random.alphanumeric(10)) while File.exist?(path)
    File.write(path, content)
    path
  end

  def make_snapshot(path, copy: true)
    basename = File.basename(path)
    target = File.join(SNAPSHOT_PATH, basename)
    FileUtils.cp_r(path, target) if copy
    target
  end

end
