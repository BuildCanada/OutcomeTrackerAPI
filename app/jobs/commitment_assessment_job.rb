class CommitmentAssessmentJob < ApplicationJob
  queue_as :default

  def perform(commitment)
    if commitment.criteria.empty?
      commitment.generate_criteria!(inline: true)
    end

    unassessed_matches = commitment.commitment_matches.unassessed.high_relevance.includes(:matchable)
    return if unassessed_matches.empty?

    evidence_items = unassessed_matches.map(&:matchable).compact
    latest_evidence_date = evidence_items.filter_map { |m| evidence_date_for(m) }.max || Time.current

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
        assessed_at: latest_evidence_date
      )

      criterion.update!(
        status: new_status,
        evidence_notes: assessor.assessment["evidence_notes"],
        assessed_at: latest_evidence_date
      )
    end

    unassessed_matches.update_all(assessed: true, assessed_at: latest_evidence_date)
    commitment.update!(last_assessed_at: latest_evidence_date)
    CommitmentStatusDerivationJob.perform_later(commitment)
  end

  private

  def evidence_date_for(matchable)
    case matchable
    when Entry then matchable.published_at
    when Bill then [matchable.passed_house_first_reading_at, matchable.latest_activity_at].compact.max
    when StatcanDataset then matchable.last_synced_at
    end
  end
end
