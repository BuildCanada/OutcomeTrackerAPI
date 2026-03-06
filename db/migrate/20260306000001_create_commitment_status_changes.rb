class CreateCommitmentStatusChanges < ActiveRecord::Migration[8.0]
  def change
    create_table :commitment_status_changes do |t|
      t.references :commitment, null: false, foreign_key: true
      t.integer :previous_status, null: false
      t.integer :new_status, null: false
      t.datetime :changed_at, null: false
      t.text :reason
      t.timestamps
    end

    add_index :commitment_status_changes, [:commitment_id, :changed_at]
  end
end
