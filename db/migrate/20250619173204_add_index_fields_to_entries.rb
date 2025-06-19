class AddIndexFieldsToEntries < ActiveRecord::Migration[8.0]
  def change
    add_column :entries, :is_index, :boolean
    add_reference :entries, :parent, null: true, foreign_key: { to_table: :entries, primary_key: :id }
  end
end
