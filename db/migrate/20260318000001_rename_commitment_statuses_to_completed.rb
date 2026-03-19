class RenameCommitmentStatusesToCompleted < ActiveRecord::Migration[8.0]
  def up
    # partially_implemented (2) is now completed (2) — no change needed for those rows.
    # implemented (3) needs to become completed (2).
    execute <<~SQL
      UPDATE commitments SET status = 2 WHERE status = 3;
      UPDATE commitment_status_changes SET previous_status = 2 WHERE previous_status = 3;
      UPDATE commitment_status_changes SET new_status = 2 WHERE new_status = 3;
    SQL
  end

  def down
    # Cannot distinguish which rows were previously "implemented" vs "partially_implemented"
    raise ActiveRecord::IrreversibleMigration
  end
end
