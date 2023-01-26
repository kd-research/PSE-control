# frozen_string_literal: true

##
# A global asset storage manager used to store/exchange files
module StorageLoader
  STORAGE_BASE = File.expand_path('../../storage', __FILE__).freeze

  def self.storage_base=(val)
    @storage_base_custom = val
  end

  def self.storage_base
    @storage_base_custom || STORAGE_BASE
  end

  ##
  # Path to storage asset related to pwd
  def self.get_path(filepath)
    File.expand_path(filepath, storage_base)
  end

  ##
  # Absolute path to storage asset, used for inter-process communication
  def self.get_absolute_path(filepath)
    File.absolute_path(File.expand_path(filepath, storage_base))
  end
end
