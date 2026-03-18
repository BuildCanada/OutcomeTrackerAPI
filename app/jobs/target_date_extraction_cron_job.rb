class TargetDateExtractionCronJob < ApplicationJob
  queue_as :default

  def perform
    Commitment.where(target_date: nil).find_each do |commitment|
      TargetDateExtractionJob.perform_later(commitment)
    end
  end
end
