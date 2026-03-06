class FeedItem < ApplicationRecord
  belongs_to :feedable, polymorphic: true
  belongs_to :commitment
  belongs_to :policy_area, optional: true

  validates :event_type, presence: true
  validates :title, presence: true
  validates :occurred_at, presence: true

  scope :newest_first, -> { order(occurred_at: :desc) }
  scope :by_event_type, ->(type) { where(event_type: type) if type.present? }
  scope :by_policy_area, ->(id) { where(policy_area_id: id) if id.present? }
  scope :by_commitment, ->(id) { where(commitment_id: id) if id.present? }
  scope :since, ->(date) { where("occurred_at >= ?", date) if date.present? }
  scope :until_date, ->(date) { where("occurred_at <= ?", date) if date.present? }
end
