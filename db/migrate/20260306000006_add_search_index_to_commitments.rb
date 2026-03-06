class AddSearchIndexToCommitments < ActiveRecord::Migration[8.0]
  def up
    execute <<~SQL
      CREATE INDEX index_commitments_on_search
      ON commitments
      USING gin(to_tsvector('english', coalesce(title, '') || ' ' || coalesce(description, '')))
    SQL
  end

  def down
    execute "DROP INDEX index_commitments_on_search"
  end
end
