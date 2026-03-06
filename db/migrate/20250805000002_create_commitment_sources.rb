class CreateCommitmentSources < ActiveRecord::Migration[8.0]
  def change
    create_table :commitment_sources do |t|
      t.references :commitment, null: false, foreign_key: true
      t.integer :source_type, null: false
      t.string :title
      t.string :url
      t.date :date
      t.text :excerpt

      t.timestamps
    end

    add_index :commitment_sources, :source_type
  end
end
