class AddPositionToPolicyAreas < ActiveRecord::Migration[8.0]
  def change
    add_column :policy_areas, :position, :integer, default: 0, null: false
  end
end
