class AddSupersededByToCommitments < ActiveRecord::Migration[8.0]
  def change
    add_reference :commitments, :superseded_by, foreign_key: { to_table: :commitments }
  end
end
