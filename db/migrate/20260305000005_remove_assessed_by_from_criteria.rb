class RemoveAssessedByFromCriteria < ActiveRecord::Migration[8.0]
  def change
    remove_index :criteria, [:assessed_by_type, :assessed_by_id]
    remove_column :criteria, :assessed_by_type, :string
    remove_column :criteria, :assessed_by_id, :bigint
  end
end
