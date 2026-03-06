class Source < ApplicationRecord
  belongs_to :government
  belongs_to :source_document, optional: true

  has_many :commitment_sources, dependent: :destroy
  has_many :commitments, through: :commitment_sources
  has_many :criterion_assessments

  enum :source_type, {
    platform_document: 0,
    speech_from_throne: 1,
    budget: 2,
    press_conference: 3,
    mandate_letter: 4,
    debate: 5,
    other: 6,
    order_in_council: 7,
    treasury_board_submission: 8,
    gazette_notice: 9,
    committee_report: 10,
    departmental_results_report: 11
  }

  validates :title, presence: true
  validates :source_type, presence: true
  validates :source_type_other, presence: true, if: :other?
end
