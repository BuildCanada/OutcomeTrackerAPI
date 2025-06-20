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
      :source_type,
      :bc_promise_rank,
      :bc_promise_direction,
      :bc_promise_rank_rationale,
      :parliament_session_id,
      :responsible_department_lead,
      :reporting_lead_title,
      :category,
      :date_issued,
      :progress_score,
      :progress_summary,
      :concise_title,
      :description,
      :what_it_means_for_canadians,
      :intended_impact_and_objectives,
      :background_and_context,
      :region_code,
      :party_code,
      :status,
      :deleted_at,
      :deleted_by_admin,
      :department,
      :evidence_ids
    ]
  end
  
end
