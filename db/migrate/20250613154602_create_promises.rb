class CreatePromises < ActiveRecord::Migration[8.0]
  def change
    create_table :promises do |t|
      t.string :promise_id
      t.datetime :action_type_classified_at
      t.integer :action_type_confidence
      t.text :action_type_rationale
      t.text :background_and_context
      t.integer :bc_priority_score
      t.string :bc_promise_direction
      t.string :bc_promise_rank
      t.text :bc_promise_rank_rationale
      t.datetime :bc_ranked_at
      t.string :candidate_or_government
      t.string :category
      t.string :concise_title
      t.date :date_issued
      t.text :description
      t.integer :evidence_count
      t.datetime :evidence_sync_fixed_at
      t.datetime :explanation_enriched_at
      t.string :explanation_enrichment_model
      t.string :explanation_enrichment_status
      t.datetime :history_generated_at
      t.string :implied_action_type
      t.datetime :ingested_at
      t.string :keywords_context_used
      t.datetime :keywords_enriched_at
      t.string :keywords_enrichment_status
      t.datetime :keywords_extracted_at
      t.datetime :last_enrichment_at
      t.datetime :last_evidence_date
      t.datetime :last_progress_update_at
      t.datetime :last_scored_at
      t.datetime :last_updated_at
      t.datetime :linking_preprocessing_done_at
      t.datetime :linking_processed_at
      t.string :linking_status
      t.datetime :migration_status_ed_at
      t.string :migration_version
      t.string :parliament_session_id
      t.string :party
      t.string :party_code
      t.integer :progress_score
      t.integer :progress_score_1_to_5
      t.string :progress_scoring_model
      t.string :progress_status
      t.text :progress_summary
      t.datetime :rationale_format_fixed_at
      t.string :region_code
      t.string :responsible_department_lead
      t.string :scoring_method
      t.string :scoring_model
      t.string :source_document_url
      t.string :source_type
      t.string :status
      t.text :text

      t.text :extracted_keywords_concepts, array: true, default: []
      t.text :intended_impact_and_objectives, array: true, default: []
      t.text :what_it_means_for_canadians, array: true, default: []

      t.text :linked_evidence_ids, array: true, default: []
      t.text :relevant_departments, array: true, default: []

      t.jsonb :commitment_history_rationale, default: {}
      t.jsonb :commitment_history_timeline, default: {}
      t.jsonb :key_points, default: {}
      t.jsonb :policy_areas, default: {}
      t.jsonb :target_groups, default: {}

      t.timestamps
    end
  end
end
