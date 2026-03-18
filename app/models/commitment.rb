class Commitment < ApplicationRecord
  attr_accessor :drift_source, :drift_change_summary, :abandonment_reason

  belongs_to :government
  belongs_to :policy_area, optional: true
  belongs_to :parent, class_name: "Commitment", optional: true

  has_many :children, class_name: "Commitment", foreign_key: :parent_id, dependent: :destroy
  has_many :commitment_sources, dependent: :destroy
  has_many :sources, through: :commitment_sources
  has_many :criteria, dependent: :destroy
  has_many :commitment_matches, dependent: :destroy
  has_many :commitment_departments, dependent: :destroy
  has_many :departments, through: :commitment_departments
  has_one :lead_commitment_department, -> { where(is_lead: true) }, class_name: "CommitmentDepartment"
  has_one :lead_department, through: :lead_commitment_department, source: :department
  has_many :completion_criteria, -> { where(category: :completion) }, class_name: "Criterion"
  has_many :success_criteria, -> { where(category: :success) }, class_name: "Criterion"
  has_many :progress_criteria, -> { where(category: :progress) }, class_name: "Criterion"
  has_many :failure_criteria, -> { where(category: :failure) }, class_name: "Criterion"
  has_many :status_changes, class_name: "CommitmentStatusChange", dependent: :destroy
  has_many :events, class_name: "CommitmentEvent", dependent: :destroy
  has_many :revisions, class_name: "CommitmentRevision", dependent: :destroy
  has_many :feed_items, dependent: :destroy

  enum :commitment_type, {
    legislative: 0,
    spending: 1,
    procedural: 2,
    institutional: 3,
    diplomatic: 4,
    aspirational: 5,
    outcome: 6
  }

  enum :status, {
    not_started: 0,
    in_progress: 1,
    partially_implemented: 2,
    implemented: 3,
    abandoned: 4
  }

  validates :title, presence: true
  validates :description, presence: true
  validates :commitment_type, presence: true
  validates :status, presence: true

  after_update :track_status_change, if: :saved_change_to_status?
  after_update :snapshot_revision, if: :tracking_drift?

  def generate_criteria!(inline: false)
    unless inline
      return CriteriaGeneratorJob.perform_later(self)
    end

    generator = CriteriaGenerator.create!(record: self, model_id: "gemini-3.1-pro-preview")
    generator.generate_criteria!
  end

  def derive_status_from_criteria!
    CommitmentStatusDerivationJob.perform_later(self)
  end

  def self.ransackable_attributes(auth_object = nil)
    %w[title status commitment_type]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[government policy_area]
  end

  def self.search(query)
    if query.present?
      where("to_tsvector('english', coalesce(title, '') || ' ' || coalesce(description, '')) @@ plainto_tsquery('english', ?)", query)
    else
      all
    end
  end

  def announcements
    events.where(action_type: :announcement).order(occurred_at: :desc)
  end

  def actions
    events.where(action_type: :concrete_action).order(occurred_at: :desc)
  end

  private

  def track_status_change
    previous, current = saved_change_to_status
    status_changes.create!(
      previous_status: previous,
      new_status: current,
      changed_at: Time.current,
      reason: abandonment_reason
    )
  ensure
    self.abandonment_reason = nil
  end

  def tracking_drift?
    saved_change_to_title? || saved_change_to_description? || saved_change_to_original_text? || saved_change_to_target_date?
  end

  def snapshot_revision
    changes = {}
    changes[:title] = saved_changes[:title]&.first if saved_change_to_title?
    changes[:description] = saved_changes[:description]&.first if saved_change_to_description?
    changes[:original_text] = saved_changes[:original_text]&.first if saved_change_to_original_text?
    changes[:target_date] = saved_changes[:target_date]&.first if saved_change_to_target_date?

    revisions.create!(
      title: changes[:title] || title,
      description: changes[:description] || description,
      original_text: changes[:original_text] || original_text,
      target_date: changes[:target_date] || target_date,
      revision_date: drift_source&.date || Date.current,
      source: drift_source,
      change_summary: drift_change_summary
    )
  ensure
    self.drift_source = nil
    self.drift_change_summary = nil
  end
end
