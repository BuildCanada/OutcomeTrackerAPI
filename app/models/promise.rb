class Promise < ApplicationRecord
  has_many :evidences, dependent: :destroy
  has_many :activities, through: :evidences
  has_many :entries, through: :activities

  has_many :department_promises, dependent: :destroy
  # has_many :relevant_departments, through: :department_promises, source: :department
  has_one :lead_department_promise, -> { where(is_lead: true) }, class_name: "DepartmentPromise"
  has_one :lead_department, through: :lead_department_promise, source: :department

  def self.ransackable_attributes(auth_object = nil)
    [ "concise_title" ]
  end

  def set_last_evidence_date!
    self.last_evidence_date = evidences.where.not(impact: "neutral").map(&:activity).maximum(:published_at)
    self.save!(touch: false)
  end

  def link_department!(department, is_lead: false)
    Rails.logger.info("Linking department #{department.slug} to promise #{promise_id}")
    if is_lead
      lead_department_promise&.update(is_lead: false)
    end

    dp = department_promises.find_or_initialize_by(department: department)
    dp.is_lead = is_lead
    dp.save!
  end

  def format_for_llm
    {
      promise_id: promise_id,
      title: concise_title,
      description: description,
      text: text
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
