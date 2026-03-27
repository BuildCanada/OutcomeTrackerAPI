class CreateSources < ActiveRecord::Migration[8.0]
  def change
    create_table :sources do |t|
      t.references :government, null: false, foreign_key: true
      t.integer :source_type, null: false
      t.string :title, null: false
      t.string :url
      t.date :date
      t.timestamps
    end

    add_index :sources, :source_type
    add_index :sources, [ :government_id, :source_type ]
  end
end
