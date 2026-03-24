module Api
  module Agent
    class SourcesController < BaseController
      def create
        source = Source.find_by(url: params[:url])

        if source
          render json: { id: source.id, existed: true }
          return
        end

        source_type = params.require(:source_type)
        source_type_other = nil

        # If the source_type isn't a known enum value, store as "other"
        unless Source.source_types.key?(source_type)
          source_type_other = source_type
          source_type = "other"
        end

        # Allow explicit source_type_other from the request
        source_type_other = params[:source_type_other] if params[:source_type_other].present? && source_type_other.nil?

        source = Source.create!(
          government_id: params.require(:government_id),
          url: params[:url],
          title: params.require(:title),
          source_type: source_type,
          source_type_other: source_type_other,
          date: params[:date],
        )

        render json: { id: source.id, existed: false }, status: :created
      end
    end
  end
end
