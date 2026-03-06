class CreateCriterionAssessments < ActiveRecord::Migration[8.0]
  def change
    create_table :criterion_assessments do |t|
      t.references :criterion, null: false, foreign_key: true
      t.integer :previous_status, null: false
      t.integer :new_status, null: false
      t.references :source, null: true, foreign_key: true
      t.text :evidence_notes
      t.datetime :assessed_at, null: false

      t.timestamps
    end

    add_index :criterion_assessments, [:criterion_id, :assessed_at]
  end
end
