class RemovePromiseFromCommitments < ActiveRecord::Migration[8.0]
  def change
    remove_foreign_key :commitments, :promises
    remove_column :commitments, :promise_id, :bigint
  end
end
