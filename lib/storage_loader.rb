# frozen_string_literal: true

##
# A global asset storage manager used to store/exchange files
module StorageLoader
  STORAGE_BASE = File.expand_path('../../storage', __FILE__).freeze
  private_constant :STORAGE_BASE

  ##
  # Path to storage asset related to pwd
  def self.get_path(filepath)
    File.expand_path(filepath, STORAGE_BASE)
  end

  ##
  # Absolute path to storage asset, used for inter-process communication
  def self.get_absolute_path(filepath)
    File.absolute_path(File.expand_path(filepath, STORAGE_BASE))
  end
  # @todo: check if this is needed later
  def self.LoadNumpyMatrix(filename); end
end
