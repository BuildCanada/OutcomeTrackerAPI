class CommitmentMatch < ApplicationRecord
  belongs_to :commitment
  belongs_to :matchable, polymorphic: true

  scope :unassessed, -> { where(assessed: false) }
  scope :high_relevance, -> { where("relevance_score >= ?", 0.6) }

  validates :relevance_score, presence: true,
    numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 1 }
  validates :matched_at, presence: true
end
