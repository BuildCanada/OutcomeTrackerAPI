class CriterionAssessment < ApplicationRecord
  belongs_to :criterion
  belongs_to :source, optional: true

  enum :previous_status, Criterion.statuses, prefix: :previous
  enum :new_status, Criterion.statuses, prefix: :new

  validates :previous_status, presence: true
  validates :new_status, presence: true
  validates :assessed_at, presence: true

  after_create :create_feed_item

  private

  def create_feed_item
    commitment = criterion.commitment
    FeedItem.create!(
      feedable: self,
      commitment: commitment,
      policy_area: commitment.policy_area,
      event_type: "criterion_assessed",
      title: "#{criterion.category.humanize} criterion updated: #{new_status}",
      summary: evidence_notes,
      occurred_at: assessed_at
    )
  end

end
