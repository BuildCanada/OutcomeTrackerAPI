class CommitmentEvent < ApplicationRecord
  belongs_to :commitment
  belongs_to :source, optional: true

  enum :event_type, {
    promised: 0,
    mentioned: 1,
    legislative_action: 2,
    funding_allocated: 3,
    status_change: 4,
    criterion_assessed: 5
  }

  enum :action_type, {
    announcement: 0,
    concrete_action: 1
  }, prefix: true

  validates :event_type, presence: true
  validates :title, presence: true
  validates :occurred_at, presence: true

  after_create :create_feed_item

  private

  def create_feed_item
    FeedItem.create!(
      feedable: self,
      commitment: commitment,
      policy_area: commitment.policy_area,
      event_type: "event",
      title: title,
      summary: description,
      occurred_at: occurred_at
    )
  end
end
