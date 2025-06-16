module Admin
    class PromisesController < ApplicationController
      def index
        promises = Promise.all

        if params[:search].present?
          query = "%#{params[:search]}%"
          promises = promises.where("title ILIKE :q OR description ILIKE :q", q: query)
        end

        promises = promises.order(created_at: :desc)
                           .limit(params[:limit] || 25)
                           .offset(params[:offset] || 0)

        render json: {
          data: promises.as_json(only: [:id, :title, :description, :status], methods: [:evidence_ids]),
          meta: {
            total: promises.count
          }
        }
      end

      def show
        promise = Promise.find(params[:id])
        render json: promise.as_json(include: { evidence: { only: [:id, :title, :source_url] } })
      end

      def update
        promise = Promise.find(params[:id])

        if params[:promise][:evidence_ids].present?
          merged_ids = (promise.evidence_ids + params[:promise][:evidence_ids].map(&:to_i)).uniq
          promise.evidence_ids = merged_ids
        end

        if promise.update(promise_params.except(:evidence_ids))
          render json: { success: true, data: promise }
        else
          render json: { success: false, errors: promise.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def promise_params
        params.require(:promise).permit!
      end
    end
  end
