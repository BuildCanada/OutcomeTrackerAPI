class CreatePolicyAreas < ActiveRecord::Migration[8.0]
  def change
    create_table :policy_areas do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.text :description

      t.timestamps
    end

    add_index :policy_areas, :name, unique: true
    add_index :policy_areas, :slug, unique: true
  end
end
