class SourceDocument < ApplicationRecord
  belongs_to :government

  has_one_attached :document
  has_one :source

  enum :status, { pending: 0, processing: 1, extracted: 2, failed: 3 }
  enum :source_type, Source.source_types

  validates :title, presence: true
  validates :source_type, presence: true
  validates :document, presence: true, on: :create

  after_commit :enqueue_processing!, on: :create

  private

  def enqueue_processing!
    SourceDocumentProcessorJob.perform_later(self)
  end
end
