class CreateEntries < ActiveRecord::Migration[8.0]
  def change
    create_table :entries do |t|
      t.references :feed, null: false, foreign_key: true
      t.string :title
      t.timestamp :published_at
      t.string :external_id
      t.string :url
      t.timestamp :scraped_at
      t.string :summary
      t.references :government, null: false, foreign_key: true
      t.jsonb :raw
      t.string :raw_html
      t.string :parsed_html
      t.string :parsed_markdown



      t.timestamps
    end
  end
end
