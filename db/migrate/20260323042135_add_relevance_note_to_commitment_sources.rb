class AddRelevanceNoteToCommitmentSources < ActiveRecord::Migration[8.0]
  def change
    add_column :commitment_sources, :relevance_note, :text
  end
end
