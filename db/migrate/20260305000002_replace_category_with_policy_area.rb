class ReplaceCategoryWithPolicyArea < ActiveRecord::Migration[8.0]
  def change
    add_reference :commitments, :policy_area, null: true, foreign_key: true
    remove_column :commitments, :category, :string
  end
end
