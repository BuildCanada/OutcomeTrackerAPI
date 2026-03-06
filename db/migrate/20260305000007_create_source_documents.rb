class CreateSourceDocuments < ActiveRecord::Migration[8.0]
  def change
    create_table :source_documents do |t|
      t.references :government, null: false, foreign_key: true
      t.integer :source_type, null: false
      t.string :title, null: false
      t.string :url
      t.date :date
      t.integer :status, default: 0, null: false
      t.jsonb :extraction_metadata, default: {}
      t.text :error_message
      t.timestamps
    end
  end
end
