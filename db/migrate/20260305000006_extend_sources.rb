class ExtendSources < ActiveRecord::Migration[8.0]
  def change
    add_column :sources, :source_type_other, :string
  end
end
