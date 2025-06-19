class AddTypeToChat < ActiveRecord::Migration[8.0]
  def change
    add_column :chats, :type, :string
  end
end
