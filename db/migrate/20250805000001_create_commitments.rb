class CreateCommitments < ActiveRecord::Migration[8.0]
  def change
    create_table :commitments do |t|
      t.references :government, null: false, foreign_key: true
      t.references :promise, null: true, foreign_key: true
      t.references :parent, null: true, foreign_key: { to_table: :commitments }
      t.string :title, null: false
      t.text :description, null: false
      t.text :original_text
      t.integer :commitment_type, null: false
      t.integer :status, null: false, default: 0
      t.string :category
      t.date :date_promised
      t.date :target_date
      t.integer :progress_score
      t.text :progress_summary
      t.datetime :last_assessed_at
      t.string :region_code
      t.string :party_code
      t.jsonb :metadata, default: {}

      t.timestamps
    end

    add_index :commitments, :commitment_type
    add_index :commitments, :status
    add_index :commitments, [ :government_id, :commitment_type ]
    add_index :commitments, [ :government_id, :status ]
  end
end
