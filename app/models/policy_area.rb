class PolicyArea < ApplicationRecord
  has_many :commitments
  has_many :feed_items

  validates :name, presence: true, uniqueness: true
  validates :slug, presence: true, uniqueness: true

  scope :ordered, -> { order(:position, :name) }

  def self.ransackable_attributes(auth_object = nil)
    %w[name slug]
  end
end
