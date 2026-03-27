class CreateCommitmentDepartments < ActiveRecord::Migration[8.0]
  def change
    create_table :commitment_departments do |t|
      t.references :commitment, null: false, foreign_key: true
      t.references :department, null: false, foreign_key: true
      t.boolean :is_lead, null: false, default: false

      t.timestamps
    end

    add_index :commitment_departments, [ :commitment_id, :department_id ], unique: true
  end
end
