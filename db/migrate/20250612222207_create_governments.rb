class CreateGovernments < ActiveRecord::Migration[8.0]
  def change
    create_table :governments do |t|
      t.string :name, null: false
      t.string :slug, null: false

      t.timestamps
    end
  end
end
