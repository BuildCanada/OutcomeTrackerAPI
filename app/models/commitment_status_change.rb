class CommitmentStatusChange < ApplicationRecord
  belongs_to :commitment
  belongs_to :source, optional: true

  enum :previous_status, Commitment.statuses, prefix: :previous
  enum :new_status, Commitment.statuses, prefix: :new

  validates :previous_status, presence: true
  validates :new_status, presence: true
  validates :changed_at, presence: true

  after_create :create_feed_item

  private

  def create_feed_item
    FeedItem.create!(
      feedable: self,
      commitment: commitment,
      policy_area: commitment.policy_area,
      event_type: "status_change",
      title: "#{commitment.title} status changed to #{new_status}",
      summary: reason,
      occurred_at: changed_at
    )
  end
end
