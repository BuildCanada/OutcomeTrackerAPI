class CreateBills < ActiveRecord::Migration[8.0]
  def change
    create_table :bills do |t|
      t.integer :bill_id, null: false
      t.text :bill_number_formatted, null: false
      t.integer :parliament_number, null: false

      t.text :short_title
      t.text :long_title
      t.text :latest_activity

      t.jsonb :data, null: false

      t.timestamptz :passed_house_first_reading_at
      t.timestamptz :passed_house_second_reading_at
      t.timestamptz :passed_house_third_reading_at
      t.timestamptz :passed_senate_first_reading_at
      t.timestamptz :passed_senate_second_reading_at
      t.timestamptz :passed_senate_third_reading_at
      t.timestamptz :received_royal_assent_at
      t.timestamptz :latest_activity_at

      t.timestamps
    end

    add_index :bills, :bill_id, unique: true
    add_index :bills, [ :parliament_number, :bill_number_formatted ], unique: true
    add_index :bills, :parliament_number
    add_index :bills, :latest_activity_at
  end
end
