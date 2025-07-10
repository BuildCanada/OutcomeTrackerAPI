class CreateStatcanDatasets < ActiveRecord::Migration[8.0]
  def change
    create_table :statcan_datasets do |t|
      t.text :statcan_url, null: false
      t.string :name, null: false
      t.string :sync_schedule, null: false
      t.jsonb :current_data
      t.timestamp :last_synced_at

      t.timestamps
    end

    add_index :statcan_datasets, :statcan_url, unique: true
    add_index :statcan_datasets, :name, unique: true
    add_index :statcan_datasets, :last_synced_at
  end
end
