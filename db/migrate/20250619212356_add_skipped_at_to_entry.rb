class AddSkippedAtToEntry < ActiveRecord::Migration[8.0]
  def change
    add_column :entries, :skipped_at, :timestamp
    add_column :entries, :skip_reason, :string
  end
end
