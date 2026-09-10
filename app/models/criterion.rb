class Criterion < ApplicationRecord
  belongs_to :commitment

  has_many :criterion_assessments, dependent: :destroy

  enum :category, {
    completion: 0,
    success: 1,
    progress: 2,
    failure: 3
  }

  # scopes: false — `not_met` would collide with the `not_met` negative scope
  # Rails auto-generates for `met`. Predicate methods (met?, not_met?) are kept.
  enum :status, {
    not_assessed: 0,
    met: 1,
    not_met: 3,
    no_longer_applicable: 4
  }, scopes: false

  validates :category, presence: true
  validates :description, presence: true
  validates :status, presence: true
end
