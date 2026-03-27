module Api
  module Agent
    class CriteriaController < BaseController
      def update
        criterion = Criterion.find(params[:id])
        previous_status = criterion.status

        new_status = params.require(:new_status)
        evidence_notes = params.require(:evidence_notes)
        source_url = params.require(:source_url)

        source = Source.find_by(url: source_url)
        unless source
          render json: { error: "Source not found for URL: #{source_url}. Fetch the page first using pages/fetch." }, status: :unprocessable_entity
          return
        end

        criterion.update!(
          status: new_status,
          evidence_notes: evidence_notes,
          assessed_at: Time.current,
        )

        criterion.criterion_assessments.create!(
          previous_status: Criterion.statuses[previous_status],
          new_status: Criterion.statuses[new_status],
          evidence_notes: evidence_notes,
          assessed_at: Time.current,
          source: source,
        )

        render json: {
          id: criterion.id,
          previous_status: previous_status,
          new_status: criterion.status,
          evidence_notes: evidence_notes,
          source_id: source.id
        }
      end
    end
  end
end
