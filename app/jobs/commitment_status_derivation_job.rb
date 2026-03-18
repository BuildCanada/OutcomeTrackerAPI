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

    commitment.update!(status: recommended)

    commitment.status_changes.create!(
      previous_status: commitment.status_before_last_save,
      new_status: recommended,
      changed_at: Time.current,
      reason: "AI-derived: #{reasoning}"
    )
  end
end
