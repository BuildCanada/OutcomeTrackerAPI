class CreateCommitmentEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :commitment_events do |t|
      t.references :commitment, null: false, foreign_key: true
      t.references :source, foreign_key: true
      t.integer :event_type, null: false
      t.integer :action_type
      t.string :title, null: false
      t.text :description
      t.date :occurred_at, null: false
      t.jsonb :metadata, default: {}
      t.timestamps
    end

    add_index :commitment_events, [ :commitment_id, :occurred_at ]
    add_index :commitment_events, :event_type
    add_index :commitment_events, :action_type
  end
end
