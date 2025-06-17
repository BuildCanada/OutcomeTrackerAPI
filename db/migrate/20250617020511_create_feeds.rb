class CreateFeeds < ActiveRecord::Migration[8.0]
  def change
    create_table :feeds do |t|
      t.string :title
      t.text :description
      t.string :language
      t.string :url
      t.timestamp :last_scraped
      t.jsonb :raw
      t.string :source_url
      t.references :government, null: false, foreign_key: true

      t.timestamps
    end
  end
end
