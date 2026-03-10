class RemovePartiallyMetStatus < ActiveRecord::Migration[8.0]
  def up
    # Convert any remaining partially_met criteria (integer value 2) to not_met (integer value 3)
    execute <<~SQL
      UPDATE criteria SET status = 3 WHERE status = 2
    SQL
  end

  def down
    # Cannot restore original partially_met statuses
  end
end
