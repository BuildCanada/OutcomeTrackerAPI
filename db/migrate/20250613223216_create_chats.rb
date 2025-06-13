class CreateChats < ActiveRecord::Migration[8.0]
  def change
    create_table :chats do |t|
      t.string :model_id
      t.bigint :record_id
      t.string :record_type

      t.timestamps
    end
  end
end
