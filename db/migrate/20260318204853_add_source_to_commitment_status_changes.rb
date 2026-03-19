class AddSourceToCommitmentStatusChanges < ActiveRecord::Migration[8.0]
  def change
    add_reference :commitment_status_changes, :source, null: true, foreign_key: true
  end
end
