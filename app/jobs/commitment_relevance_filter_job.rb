class CommitmentRelevanceFilterJob < ApplicationJob
  queue_as :default

  def perform(matchable)
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
          cm.matched_at = Time.current
        end
      end
    end
  end

  private

  def active_commitments_for(matchable)
    scope = Commitment.where.not(status: [:abandoned, :superseded])

    if matchable.respond_to?(:government_id) && matchable.government_id.present?
      scope.where(government_id: matchable.government_id)
    else
      scope
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
