class AddSourceDocumentIdToSources < ActiveRecord::Migration[8.0]
  def change
    add_reference :sources, :source_document, null: true, foreign_key: true
  end
end
