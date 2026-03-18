class AddContactFieldsToMinisters < ActiveRecord::Migration[8.0]
  def change
    add_column :ministers, :person_id, :integer
    add_column :ministers, :email, :string
    add_column :ministers, :phone, :string
    add_column :ministers, :constituency, :string
    add_column :ministers, :province, :string
    add_column :ministers, :party, :string
    add_column :ministers, :website, :string
    add_column :ministers, :contact_data, :jsonb, default: {}

    add_index :ministers, [ :person_id, :department_id ], unique: true
  end
end
