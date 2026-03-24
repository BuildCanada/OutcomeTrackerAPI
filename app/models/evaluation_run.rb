class EvaluationRun < ApplicationRecord
  belongs_to :commitment

  validates :trigger_type, presence: true
  validates :reasoning, presence: true
end
