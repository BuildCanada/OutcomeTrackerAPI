class CreateCommitmentMatches < ActiveRecord::Migration[8.0]
  def change
    create_table :commitment_matches do |t|
      t.references :commitment, null: false, foreign_key: true
      t.string :matchable_type, null: false
      t.bigint :matchable_id, null: false
      t.float :relevance_score, null: false
      t.text :relevance_reasoning
      t.datetime :matched_at, null: false
      t.boolean :assessed, default: false, null: false
      t.datetime :assessed_at
      t.jsonb :metadata, default: {}
      t.timestamps
    end

    add_index :commitment_matches, [ :commitment_id, :matchable_type, :matchable_id ],
              unique: true, name: "idx_commitment_matches_unique"
    add_index :commitment_matches, [ :matchable_type, :matchable_id ],
              name: "idx_commitment_matches_matchable"
    add_index :commitment_matches, [ :commitment_id, :assessed ],
              name: "idx_commitment_matches_unassessed"
  end
end
