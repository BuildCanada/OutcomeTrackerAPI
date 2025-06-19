class CreateActivities < ActiveRecord::Migration[8.0]
  def change
    create_table :activities do |t|
      t.references :entry, null: false, foreign_key: true
      t.references :government, null: false, foreign_key: true
      t.string :title
      t.string :summary
      t.string :source_url
      t.jsonb :info
      t.timestamp :published_at

      t.timestamps
    end
  end
end
