class CriterionAssessment < ApplicationRecord
  belongs_to :criterion
  belongs_to :source, optional: true

  enum :previous_status, Criterion.statuses, prefix: :previous
  enum :new_status, Criterion.statuses, prefix: :new

  validates :previous_status, presence: true
  validates :new_status, presence: true
  validates :assessed_at, presence: true
end
