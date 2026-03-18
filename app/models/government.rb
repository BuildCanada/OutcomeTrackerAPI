class Government < ApplicationRecord
  has_many :commitments, dependent: :destroy
  has_many :departments, dependent: :destroy
  has_many :ministers, dependent: :destroy
  has_many :source_documents, dependent: :destroy
  has_many :sources, dependent: :destroy
end
