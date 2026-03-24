class CreateEvaluationRuns < ActiveRecord::Migration[8.0]
  def change
    create_table :evaluation_runs do |t|
      t.references :commitment, null: false, foreign_key: true
      t.string :agent_run_id
      t.string :trigger_type, null: false
      t.string :previous_status
      t.string :new_status
      t.text :reasoning, null: false
      t.integer :criteria_assessed, default: 0, null: false
      t.integer :evidence_found, default: 0, null: false
      t.jsonb :search_queries, default: []
      t.float :duration_seconds
      t.datetime :created_at, null: false
    end

    add_index :evaluation_runs, :agent_run_id
    add_index :evaluation_runs, [:commitment_id, :created_at]
    add_index :evaluation_runs, :trigger_type
  end
end
