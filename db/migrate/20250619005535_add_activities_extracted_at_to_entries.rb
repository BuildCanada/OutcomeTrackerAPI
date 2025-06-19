class AddActivitiesExtractedAtToEntries < ActiveRecord::Migration[8.0]
  def change
    add_column :entries, :activities_extracted_at, :timestamp
  end
end
