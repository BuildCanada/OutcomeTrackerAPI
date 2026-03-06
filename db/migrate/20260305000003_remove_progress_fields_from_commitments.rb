class RemoveProgressFieldsFromCommitments < ActiveRecord::Migration[8.0]
  def change
    remove_column :commitments, :progress_score, :integer
    remove_column :commitments, :progress_summary, :text
  end
end
