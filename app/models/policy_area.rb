class PolicyArea < ApplicationRecord
  has_many :commitments

  validates :name, presence: true, uniqueness: true
  validates :slug, presence: true, uniqueness: true

  def self.ransackable_attributes(auth_object = nil)
    %w[name slug]
  end
end
