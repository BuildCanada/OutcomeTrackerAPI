class RemoveSupersededStatus < ActiveRecord::Migration[8.0]
  def up
    # Convert superseded commitments (status: 5) to abandoned (status: 4)
    execute <<~SQL
      UPDATE commitments SET status = 4, superseded_by_id = NULL WHERE status = 5
    SQL

    # Convert superseded events (event_type: 6) to status_change (event_type: 4)
    execute <<~SQL
      UPDATE commitment_events SET event_type = 4 WHERE event_type = 6
    SQL
  end

  def down
    # No-op: cannot reliably restore which commitments were superseded
  end
end
