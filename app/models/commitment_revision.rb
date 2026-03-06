class CommitmentRevision < ApplicationRecord
  belongs_to :commitment
  belongs_to :source, optional: true

  validates :title, presence: true
  validates :description, presence: true
  validates :revision_date, presence: true

  after_create :create_feed_item

  private

  def create_feed_item
    FeedItem.create!(
      feedable: self,
      commitment: commitment,
      policy_area: commitment.policy_area,
      event_type: "drift",
      title: "#{commitment.title} revised",
      summary: change_summary,
      occurred_at: revision_date
    )
  end
end
