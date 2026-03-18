class RemoveParentCommitments < ActiveRecord::Migration[8.0]
  def up
    # Find aspirational commitments used as parents
    parent_ids = execute("SELECT DISTINCT parent_id FROM commitments WHERE parent_id IS NOT NULL").values.flatten

    # Nullify all parent_id references first
    execute("UPDATE commitments SET parent_id = NULL WHERE parent_id IS NOT NULL")

    # Delete aspirational commitments that were used as parents
    if parent_ids.any?
      execute(<<~SQL)
        DELETE FROM commitments
        WHERE id IN (#{parent_ids.join(',')})
        AND commitment_type = 5
      SQL
    end
  end

  def down
    # Cannot restore deleted parent commitments
  end
end
