class AddAgentProcessedAtToEntries < ActiveRecord::Migration[8.0]
  def change
    add_column :entries, :agent_processed_at, :datetime
  end
end
