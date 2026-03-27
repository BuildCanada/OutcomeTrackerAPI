module Api
  module Agent
    class CommitmentEventsController < BaseController
      def create
        commitment = Commitment.find(params.require(:commitment_id))
        source_url = params.require(:source_url)

        source = Source.find_by(url: source_url)
        unless source
          render json: { error: "Source not found for URL: #{source_url}. Fetch the page first using pages/fetch." }, status: :unprocessable_entity
          return
        end

        event = commitment.events.create!(
          event_type: params.require(:event_type),
          action_type: params[:action_type],
          title: params.require(:title),
          description: params[:description],
          occurred_at: params.require(:occurred_at),
          source: source,
          metadata: params[:metadata] || {},
        )

        render json: {
          id: event.id,
          commitment_id: event.commitment_id,
          event_type: event.event_type,
          title: event.title,
          source_id: source.id
        }, status: :created
      end
    end
  end
end
