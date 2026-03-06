class CommitmentAssessmentCronJob < ApplicationJob
  queue_as :default

  def perform
    commitment_ids = CommitmentMatch.unassessed.high_relevance
      .select(:commitment_id).distinct.pluck(:commitment_id)

    Commitment.where(id: commitment_ids).find_each do |commitment|
      CommitmentAssessmentJob.perform_later(commitment)
    end
  end
end
