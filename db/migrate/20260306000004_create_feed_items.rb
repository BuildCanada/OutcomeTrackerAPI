class CreateFeedItems < ActiveRecord::Migration[8.0]
  def change
    create_table :feed_items do |t|
      t.string :feedable_type, null: false
      t.bigint :feedable_id, null: false
      t.references :commitment, null: false, foreign_key: true
      t.references :policy_area, foreign_key: true
      t.string :event_type, null: false
      t.string :title, null: false
      t.text :summary
      t.datetime :occurred_at, null: false
      t.timestamps
    end

    add_index :feed_items, [:feedable_type, :feedable_id]
    add_index :feed_items, [:commitment_id, :occurred_at]
    add_index :feed_items, [:policy_area_id, :occurred_at]
    add_index :feed_items, [:event_type, :occurred_at]
    add_index :feed_items, :occurred_at
  end
end
