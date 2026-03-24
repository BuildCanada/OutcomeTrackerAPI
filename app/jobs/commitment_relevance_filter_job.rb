class CommitmentRelevanceFilterJob < ApplicationJob
  queue_as :default

  def perform(matchable)
    return if matchable.is_a?(Bill) && !matchable.government_bill?

    commitments = active_commitments_for(matchable)
    return if commitments.none?

    prompt_method = prompt_method_for(matchable)

    commitments.find_in_batches(batch_size: 20) do |batch|
      filter = CommitmentRelevanceFilter.create!(record: matchable)
      filter.extract!(filter.send(prompt_method, batch, matchable))

      filter.matches.each do |match_data|
        next if match_data["relevance_score"].to_f < 0.5

        CommitmentMatch.find_or_create_by!(
          commitment_id: match_data["commitment_id"],
          matchable: matchable
        ) do |cm|
          cm.relevance_score = match_data["relevance_score"]
          cm.relevance_reasoning = match_data["relevance_reasoning"]
          cm.matched_at = evidence_date_for(matchable) || Time.current
        end
      end
    end
  end

  private

  def active_commitments_for(matchable)
    scope = Commitment.where.not(status: :broken)

    if matchable.respond_to?(:government_id) && matchable.government_id.present?
      scope = scope.where(government_id: matchable.government_id)
    end

    evidence_date = evidence_date_for(matchable)
    if evidence_date.present?
      scope = scope.where("COALESCE(date_promised, created_at::date) <= ?", evidence_date)
    end

    scope
  end

  def evidence_date_for(matchable)
    case matchable
    when Entry then matchable.published_at&.to_date
    when Bill then matchable.passed_house_first_reading_at&.to_date
    when StatcanDataset then matchable.last_synced_at&.to_date
    end
  end

  def prompt_method_for(matchable)
    case matchable
    when Entry then :prompt_for_entry
    when Bill then :prompt_for_bill
    when StatcanDataset then :prompt_for_statcan
    else raise ArgumentError, "Unknown matchable type: #{matchable.class}"
    end
  end
end
