class AddCriteriaGeneratedAtToCommitments < ActiveRecord::Migration[8.0]
  def change
    add_column :commitments, :criteria_generated_at, :datetime
  end
end
