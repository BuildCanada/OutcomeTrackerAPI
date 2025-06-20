class Promise < ApplicationRecord
  has_many :evidences, dependent: :destroy
  has_many :activities, through: :evidences
  has_many :entries, through: :activities

  def format_for_llm
    {
      promise_id: promise_id,
      title: concise_title,
      description: description
    }
  end

  def self.client_fields
    [
      :id,
      :text,
      :concise_title,
      :description,

      :bc_promise_rank,
      :bc_promise_direction,
      :bc_promise_rank_rationale,
      :source_type,

      :responsible_department_lead,
      :reporting_lead_title,
      :category,
      :parliament_session_id,
      :date_issued,
      :status,

      :progress_score,
      :progress_summary,

      :what_it_means_for_canadians,
      :intended_impact_and_objectives,
      :background_and_context,

      :linked_evidence_ids,
      :commitment_history_rationale,

      :region_code,
      :party_code,
      :deleted_at,
      :deleted_by_admin,
      :department,
      :evidence_ids,

      # Read-only fields
      :region_code,
      :party_code,
      :migration_metadata,
      :ingested_at,
      :explanation_enriched_at,
      :linking_preprocessing_done_at
    ]
  end

end
