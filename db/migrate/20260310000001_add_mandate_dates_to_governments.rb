class AddMandateDatesToGovernments < ActiveRecord::Migration[8.0]
  def change
    add_column :governments, :mandate_start, :date
    add_column :governments, :mandate_end, :date
  end
end
