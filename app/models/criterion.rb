class Criterion < ApplicationRecord
  belongs_to :commitment

  has_many :criterion_assessments, dependent: :destroy

  enum :category, {
    completion: 0,
    success: 1,
    progress: 2,
    failure: 3
  }

  enum :status, {
    not_assessed: 0,
    met: 1,
    not_met: 3,
    no_longer_applicable: 4
  }

  validates :category, presence: true
  validates :description, presence: true
  validates :status, presence: true
end
