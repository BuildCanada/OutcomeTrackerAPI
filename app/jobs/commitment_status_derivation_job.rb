class CommitmentStatusDerivationJob < ApplicationJob
  queue_as :default

  def perform(commitment)
    return if commitment.criteria.empty?

    deriver = CommitmentStatusDeriver.create!(record: commitment)
    deriver.extract!(deriver.prompt(commitment))

    derivation = deriver.derivation
    return unless derivation

    recommended = derivation["recommended_status"]
    confidence = derivation["confidence"].to_f
    reasoning = derivation["reasoning"]

    return if recommended == commitment.status
    return if confidence < 0.7

    Rails.logger.info(
      "CommitmentStatusDerivationJob: Changing commitment ##{commitment.id} " \
      "from #{commitment.status} to #{recommended} (confidence: #{confidence}) — #{reasoning}"
    )

    evidence_date = commitment.criteria.maximum(:assessed_at)
    commitment.status_changed_at = evidence_date
    commitment.update!(status: recommended)
  end
end
