module Admin
  class PromisesController < ApplicationController
    skip_before_action :verify_authenticity_token
    def index
      base_query = Promise.all

      base_query = base_query.where(party_code: params[:party_code]) if params[:party_code].present?
      base_query = base_query.where(region_code: params[:region_code]) if params[:region_code].present?
      base_query = base_query.where(parliament_session_id: params[:parliament_session_id]) if params[:parliament_session_id].present?
      base_query = base_query.where(source_type: params[:source_type]) if params[:source_type].present? && params[:source_type] != 'all'

      if params[:bc_promise_rank].present?
        if params[:bc_promise_rank] == 'none'
          base_query = base_query.where(bc_promise_rank: nil)
        elsif params[:bc_promise_rank] != 'all'
          base_query = base_query.where(bc_promise_rank: params[:bc_promise_rank])
        end
      end

      if params[:search].present?
        query = "%#{params[:search]}%"
        base_query = base_query.where("title ILIKE :q OR description ILIKE :q", q: query)
      end

      total = base_query.count
      promises = base_query.order(created_at: :desc)
                          .limit(params[:limit] || 25)
                          .offset(params[:offset] || 0)

      render json: {
        data: promises.as_json(only: Promise.client_fields),
        meta: { total: total }
      }
    end

    def update
      promise = Promise.find(params[:id])
      puts "\n🔧 Updating Promise ID: #{promise.id}"
      puts "➡️ Incoming Params: #{params.to_unsafe_h.slice(*Promise.client_fields.map(&:to_s))}"

      if promise.update(promise_params)
        puts "✅ Update Successful"
        render json: { success: true, data: promise.as_json(only: Promise.client_fields) }
      else
        puts "❌ Update Failed: #{promise.errors.full_messages.join(', ')}"
        render json: { success: false, errors: promise.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def destroy
      promise = Promise.find(params[:id])
      puts "🗑️ Soft deleting promise #{promise.id}"

      if promise.update(
        status: 'deleted',
      )
        puts "✅ Soft delete successful"
        render json: { success: true, message: "Promise soft deleted", id: promise.id }
      else
        puts "❌ Soft delete failed: #{promise.errors.full_messages.join(', ')}"
        render json: { success: false, errors: promise.errors.full_messages }, status: :unprocessable_entity
      end
    end

    private

    def promise_params
      params.permit(*Promise.client_fields - [:id])
    end

  end
end
