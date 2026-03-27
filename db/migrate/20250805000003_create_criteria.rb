class CreateCriteria < ActiveRecord::Migration[8.0]
  def change
    create_table :criteria do |t|
      t.references :commitment, null: false, foreign_key: true
      t.integer :category, null: false
      t.text :description, null: false
      t.text :verification_method
      t.integer :status, null: false, default: 0
      t.text :evidence_notes
      t.datetime :assessed_at
      t.string :assessed_by_type
      t.bigint :assessed_by_id
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_index :criteria, :status
    add_index :criteria, [ :commitment_id, :category ]
    add_index :criteria, [ :commitment_id, :category, :status ]
    add_index :criteria, [ :assessed_by_type, :assessed_by_id ]
  end
end
