class CriteriaGenerationCronJob < ApplicationJob
  queue_as :default

  def perform
    Commitment.where(criteria_generated_at: nil).find_each do |commitment|
      CriteriaGeneratorJob.perform_later(commitment)
    end
  end
end
