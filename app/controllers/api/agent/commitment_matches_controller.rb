module Api
  module Agent
    class CommitmentMatchesController < BaseController
      def create
        match = CommitmentMatch.find_or_initialize_by(
          commitment_id: params.require(:commitment_id),
          matchable_type: params.require(:matchable_type),
          matchable_id: params.require(:matchable_id),
        )

        match.assign_attributes(
          relevance_score: params.require(:relevance_score),
          relevance_reasoning: params[:relevance_reasoning],
          matched_at: Time.current,
        )

        match.save!

        render json: {
          id: match.id,
          commitment_id: match.commitment_id,
          matchable_type: match.matchable_type,
          matchable_id: match.matchable_id,
          relevance_score: match.relevance_score,
          created: match.previously_new_record?,
        }
      end
    end
  end
end
