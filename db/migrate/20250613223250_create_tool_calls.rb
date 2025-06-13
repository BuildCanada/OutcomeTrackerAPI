class CreateToolCalls < ActiveRecord::Migration[8.0]
  def change
    create_table :tool_calls do |t|
      t.references :message, null: false, foreign_key: true
      t.string :tool_call_id
      t.string :name
      t.jsonb :arguments

      t.timestamps
    end
    add_index :tool_calls, :tool_call_id
  end
end
