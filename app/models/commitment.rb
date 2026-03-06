class Commitment < ApplicationRecord
  belongs_to :government
  belongs_to :policy_area, optional: true
  belongs_to :parent, class_name: "Commitment", optional: true
  belongs_to :superseded_by, class_name: "Commitment", optional: true

  has_many :children, class_name: "Commitment", foreign_key: :parent_id, dependent: :destroy
  has_many :supersedes, class_name: "Commitment", foreign_key: :superseded_by_id, dependent: :nullify
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
    abandoned: 4,
    superseded: 5
  }

  validates :title, presence: true
  validates :description, presence: true
  validates :commitment_type, presence: true
  validates :status, presence: true

  def generate_criteria!(inline: false)
    unless inline
      return CriteriaGeneratorJob.perform_later(self)
    end

    generator = CriteriaGenerator.create!(record: self, model_id: "gemini-3.1-pro-preview")
    generator.generate_criteria!
  end

  def derive_status_from_criteria!
    success = success_criteria.to_a
    execution = criteria.where(category: :completion).to_a
    return if success.empty?

    if success.all?(&:met?)
      update!(status: :implemented)
    elsif success.any? { |c| c.met? || c.partially_met? }
      if execution.any? { |c| c.met? || c.partially_met? }
        update!(status: :partially_implemented)
      else
        update!(status: :in_progress)
      end
    elsif execution.any? { |c| c.met? || c.partially_met? }
      update!(status: :in_progress)
    end
  end

  def self.ransackable_attributes(auth_object = nil)
    %w[title status commitment_type]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[government policy_area]
  end
end
