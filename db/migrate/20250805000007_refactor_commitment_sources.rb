class RefactorCommitmentSources < ActiveRecord::Migration[8.0]
  def change
    add_reference :commitment_sources, :source, null: false, foreign_key: true
    add_column :commitment_sources, :section, :string
    add_column :commitment_sources, :reference, :string

    remove_index :commitment_sources, :source_type
    remove_column :commitment_sources, :source_type, :integer, null: false
    remove_column :commitment_sources, :title, :string
    remove_column :commitment_sources, :url, :string
    remove_column :commitment_sources, :date, :date
  end
end
