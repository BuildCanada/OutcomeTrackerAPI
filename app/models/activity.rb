class Activity < ApplicationRecord
  belongs_to :entry
  belongs_to :government

  has_many :evidences
  has_many :promises, through: :evidences
end
