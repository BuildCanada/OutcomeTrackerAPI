class CommitmentAssessmentJob < ApplicationJob
  queue_as :default

  def perform(commitment)
    if commitment.criteria.empty?
      commitment.generate_criteria!(inline: true)
    end

    unassessed_matches = commitment.commitment_matches.unassessed.high_relevance.includes(:matchable)
    return if unassessed_matches.empty?

    evidence_items = unassessed_matches.map(&:matchable).compact

    commitment.criteria.find_each do |criterion|
      assessor = CriterionAssessor.create!(record: criterion)
      assessor.extract!(assessor.prompt(criterion, evidence_items))

      new_status = assessor.assessment["new_status"]
      next if new_status == criterion.status

      CriterionAssessment.create!(
        criterion: criterion,
        previous_status: criterion.status,
        new_status: new_status,
        evidence_notes: assessor.assessment["evidence_notes"],
        assessed_at: Time.current
      )

      criterion.update!(
        status: new_status,
        evidence_notes: assessor.assessment["evidence_notes"],
        assessed_at: Time.current
      )
    end

    unassessed_matches.update_all(assessed: true, assessed_at: Time.current)
    commitment.update!(last_assessed_at: Time.current)
    commitment.derive_status_from_criteria!
  end
end
