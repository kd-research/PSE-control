# frozen_string_literal: true

module StorageLoader
  STORAGE_BASE = File.expand_path('../../storage', __FILE__)
  def self.get_path(filepath)
    File.expand_path(filepath, STORAGE_BASE)
  end

  def self.get_absolute_path(filepath)
    File.absolute_path(File.expand_path(filepath, STORAGE_BASE))
  end
  # @todo: check if this is needed later
  def self.LoadNumpyMatrix(filename); end
end
