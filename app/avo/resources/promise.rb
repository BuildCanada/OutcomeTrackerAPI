class Avo::Resources::Promise < Avo::BaseResource
  # self.includes = []
  # self.attachments = []
  # self.search = {
  #   query: -> { query.ransack(id_eq: params[:q], m: "or").result(distinct: false) }
  # }

  self.title = :concise_title


  def fields
    field :id, as: :id
    field :concise_title, as: :text
    field "Has evidence", as: :boolean do
      record.evidences.present?
    rescue
      false
    end

    field "Has unreviewed evidence", as: :boolean do
      record.evidences.where(reviewed: [ nil, false ]).present?
    rescue
      false
    end
    # field :promise_id, as: :text
    # field :action_type_classified_at, as: :date_time
    # field :action_type_confidence, as: :number
    # field :action_type_rationale, as: :textarea
    field :background_and_context, as: :textarea
    field :bc_priority_score, as: :number, sortable: true
    field :bc_promise_direction, as: :text
    field :bc_promise_rank, as: :text
    # field :bc_promise_rank_rationale, as: :textarea
    # field :bc_ranked_at, as: :date_time
    field :candidate_or_government, as: :text
    # field :category, as: :text
    field :date_issued, as: :date
    field :description, as: :textarea
    # field :evidence_count, as: :number
    # field :evidence_sync_fixed_at, as: :date_time
    # field :explanation_enriched_at, as: :date_time
    # field :explanation_enrichment_model, as: :text
    # field :explanation_enrichment_status, as: :text
    # field :history_generated_at, as: :date_time
    # field :implied_action_type, as: :text
    field :ingested_at, as: :date_time
    # field :keywords_context_used, as: :text
    # field :keywords_enriched_at, as: :date_time
    # field :keywords_enrichment_status, as: :text
    # field :keywords_extracted_at, as: :date_time
    # field :last_enrichment_at, as: :date_time
    # field :last_evidence_date, as: :date_time
    # field :last_progress_update_at, as: :date_time
    # field :last_scored_at, as: :date_time
    # field :last_updated_at, as: :date_time
    # field :linking_preprocessing_done_at, as: :date_time
    # field :linking_processed_at, as: :date_time
    # field :linking_status, as: :text
    # field :migration_status_ed_at, as: :date_time
    # field :migration_version, as: :text
    field :parliament_session_id, as: :text
    # field :party, as: :text
    # field :party_code, as: :text
    field :progress_score, as: :number
    # field :progress_score_1_to_5, as: :number
    # field :progress_scoring_model, as: :text
    # field :progress_status, as: :text
    field :progress_summary, as: :textarea
    # field :rationale_format_fixed_at, as: :date_time
    # field :region_code, as: :text
    # field :responsible_department_lead, as: :text
    # field :scoring_method, as: :text
    # field :scoring_model, as: :text
    field :source_document_url, as: :text
    field :source_type, as: :text
    field :status, as: :text
    field :text, as: :textarea
    # field :extracted_keywords_concepts, as: :textarea
    # field :intended_impact_and_objectives, as: :textarea
    field :what_it_means_for_canadians, as: :textarea
    # field :linked_evidence_ids, as: :textarea
    # field :relevant_departments, as: :textarea
    # field :commitment_history_rationale, as: :code
    # field :commitment_history_timeline, as: :code
    # field :key_points, as: :code
    # field :policy_areas, as: :code
    # field :target_groups, as: :code

    field :evidences, as: :has_many
  end
end
