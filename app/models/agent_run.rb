class AgentRun < ApplicationRecord
  belongs_to :commitment, optional: true
  belongs_to :entry, optional: true
  has_many :events, -> { order(:sequence) }, class_name: "AgentRunEvent", dependent: :delete_all

  validates :status, inclusion: { in: %w[running succeeded failed] }
end
