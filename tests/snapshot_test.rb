# frozen_string_literal: true

require_relative "test_helper"
class SnapshotTest < Minitest::Test
  def setup
    Snapshot.reinitialize!
  end

  # test snapshot dir is empty after initialization
  def test_snapshot_dir_is_empty
    assert Dir.exist?(Snapshot::SNAPSHOT_PATH)
  end

  def test_snapshot_dir_is_empty_after_reinitialization
    Snapshot.set_snapshot_base(Dir.tmpdir)
    assert Dir.exist?(Snapshot::SNAPSHOT_PATH)
    assert Dir.empty?(Snapshot::SNAPSHOT_PATH)
  end

  def test_old_snapshot_is_removed_if_new_snapshot_is_set
    old_snapshot = Snapshot::SNAPSHOT_PATH
    assert Dir.exist?(old_snapshot)

    Snapshot.set_snapshot_base(Dir.tmpdir)
    assert Dir.exist?(Snapshot::SNAPSHOT_PATH)
    assert Dir.empty?(Snapshot::SNAPSHOT_PATH)

    refute Dir.exist?(old_snapshot)
  end
end
