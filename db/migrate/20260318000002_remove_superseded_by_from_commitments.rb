class RemoveSupersededByFromCommitments < ActiveRecord::Migration[8.0]
  def change
    remove_reference :commitments, :superseded_by, foreign_key: { to_table: :commitments }, index: true
  end
end
