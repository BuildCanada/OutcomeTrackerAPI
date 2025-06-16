module Admin
  class EvidencesController < ApplicationController
    def index
      evidences = Evidence.all

      if params[:parliament_session_id].present?
        evidences = evidences.where(parliament_session_id: params[:parliament_session_id])
      end

      if params[:search].present?
        query = "%#{params[:search]}%"
        evidences = evidences.where(
          "title ILIKE :q OR description ILIKE :q OR source_url ILIKE :q",
          q: query
        )
      end

      evidences = evidences
                    .order(created_at: :desc)
                    .limit(params[:limit] || 25)
                    .offset(params[:offset] || 0)

      render json: {
        data: evidences.as_json(only: [:id, :title, :description, :source_url, :parliament_session_id]),
        meta: {
          total: evidences.count
        }
      }
    end

    def show
      evidence = Evidence.find(params[:id])
      render json: evidence.as_json(include: { promises: { only: [:id, :title] } })
    end

    def update
      evidence = Evidence.find(params[:id])

      if evidence.update(evidence_params)
        render json: { success: true, data: evidence }
      else
        render json: { success: false, errors: evidence.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def destroy
      evidence = Evidence.find(params[:id])
      if evidence.destroy
        render json: { success: true, message: "Evidence deleted." }
      else
        render json: { success: false, errors: evidence.errors.full_messages }, status: :unprocessable_entity
      end
    end

    private

    def evidence_params
      params.require(:evidence).permit(:title, :description, :source_url, :parliament_session_id, promise_ids: [])
    end
  end
end
