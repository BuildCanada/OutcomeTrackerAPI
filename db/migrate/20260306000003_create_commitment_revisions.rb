class CreateCommitmentRevisions < ActiveRecord::Migration[8.0]
  def change
    create_table :commitment_revisions do |t|
      t.references :commitment, null: false, foreign_key: true
      t.references :source, foreign_key: true
      t.string :title, null: false
      t.text :description, null: false
      t.text :original_text
      t.date :target_date
      t.text :change_summary
      t.date :revision_date, null: false
      t.timestamps
    end

    add_index :commitment_revisions, [:commitment_id, :revision_date]
  end
end
