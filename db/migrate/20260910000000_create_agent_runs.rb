class CreateAgentRuns < ActiveRecord::Migration[8.0]
  def change
    create_table :agent_runs do |t|
      t.references :commitment, foreign_key: { on_delete: :nullify }
      t.references :entry, foreign_key: { on_delete: :nullify }
      t.string :active_job_id, index: true
      t.string :provider_job_id, index: true
      t.string :job_class, null: false
      t.integer :attempt, null: false
      t.string :session_id, index: true
      t.string :model, null: false
      t.text :prompt, null: false
      t.text :system_prompt, null: false
      t.string :status, null: false
      t.integer :exit_code
      t.text :error_message
      t.datetime :started_at, null: false, index: true
      t.datetime :finished_at
      t.timestamps
    end

    create_table :agent_run_events do |t|
      t.references :agent_run, null: false, foreign_key: { on_delete: :cascade }
      t.integer :sequence, null: false
      t.string :stream, null: false
      t.jsonb :payload, null: false
      t.timestamps
    end
    add_index :agent_run_events, [ :agent_run_id, :sequence ], unique: true
  end
end
