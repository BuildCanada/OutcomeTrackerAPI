class AddJsonAttributesToChat < ActiveRecord::Migration[8.0]
  def change
    add_column :chats, :json_attributes, :jsonb
  end
end
