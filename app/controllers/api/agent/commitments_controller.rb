module Api
  module Agent
    class CommitmentsController < BaseController
      def status
        commitment = Commitment.find(params[:id])
        previous_status = commitment.status

        new_status = params.require(:new_status)
        reasoning = params.require(:reasoning)
        source_urls = params.require(:source_urls)
        effective_date = params.require(:effective_date)

        sources = Source.where(url: source_urls)
        if sources.empty?
          render json: { error: "No sources found for provided URLs. Fetch pages first using pages/fetch." }, status: :unprocessable_entity
          return
        end

        primary_source = sources.first

        # Set transient attributes used by the after_update callback
        commitment.status_change_source = primary_source
        commitment.status_changed_at = effective_date
        commitment.status_change_reason = reasoning

        commitment.update!(status: new_status)

        render json: {
          id: commitment.id,
          previous_status: previous_status,
          new_status: commitment.status,
          reasoning: reasoning,
          effective_date: effective_date,
          source_ids: sources.pluck(:id),
        }
      end
    end
  end
end
