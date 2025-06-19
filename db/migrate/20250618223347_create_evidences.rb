class CreateEvidences < ActiveRecord::Migration[8.0]
  def change
    drop_table :evidences, if_exists: true

    create_table :evidences do |t|
      t.references :activity, null: false, foreign_key: true
      t.references :promise, null: false, foreign_key: true
      t.string :impact
      t.integer :impact_magnitude
      t.string :impact_reason
      t.timestamp :linked_at
      t.references :linked_by, null: true, foreign_key: { to_table: :users }
      t.string :link_type
      t.string :link_reason
      t.boolean :review
      t.references :reviewed_by, null: true, foreign_key: { to_table: :users }
      t.timestamp :reviewed_at

      t.timestamps
    end
  end
end
