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

      evidence_index = assessor.assessment["primary_evidence_index"]
      primary_evidence = evidence_items[evidence_index] if evidence_index&.between?(0, evidence_items.size - 1)
      primary_evidence ||= evidence_items.first
      source = source_for(primary_evidence, commitment.government)

      CriterionAssessment.create!(
        criterion: criterion,
        previous_status: criterion.status,
        new_status: new_status,
        evidence_notes: assessor.assessment["evidence_notes"],
        assessed_at: latest_evidence_date,
        source: source
      )

      criterion.update!(
        status: new_status,
        evidence_notes: assessor.assessment["evidence_notes"],
        assessed_at: latest_evidence_date
      )
    end

    unassessed_matches.update_all(assessed: true, assessed_at: latest_evidence_date)
    commitment.update!(last_assessed_at: latest_evidence_date)
  end

  private

  def evidence_date_for(matchable)
    case matchable
    when Entry then matchable.published_at
    when Bill then [matchable.passed_house_first_reading_at, matchable.latest_activity_at].compact.max
    when StatcanDataset then matchable.last_synced_at
    end
  end

  def source_for(matchable, government)
    return nil unless matchable

    case matchable
    when Bill
      Source.find_or_create_by!(
        government: government,
        source_type: :other,
        source_type_other: "Parliamentary Bill",
        title: "#{matchable.bill_number_formatted} — #{matchable.short_title}",
        url: "https://www.parl.ca/legisinfo/en/bill/#{matchable.parliament_number}-#{matchable.data&.dig('SessionNumber')}/#{matchable.bill_number_formatted}",
        date: evidence_date_for(matchable)&.to_date
      )
    when Entry
      source_type, source_type_other = source_type_for_feed(matchable.feed)
      attrs = {
        government: government,
        source_type: source_type,
        title: matchable.title,
        url: matchable.url,
        date: matchable.published_at&.to_date
      }
      attrs[:source_type_other] = source_type_other if source_type_other
      Source.find_or_create_by!(attrs)
    when StatcanDataset
      Source.find_or_create_by!(
        government: government,
        source_type: :other,
        source_type_other: "Statistics Canada Dataset",
        title: matchable.name,
        url: matchable.statcan_url,
        date: matchable.last_synced_at&.to_date
      )
    end
  end

  def source_type_for_feed(feed)
    title = feed.title.to_s.downcase
    if title.include?("gazette")
      [:gazette_notice, nil]
    elsif title.include?("committee")
      [:committee_report, nil]
    else
      [:other, feed.title]
    end
  end
end
