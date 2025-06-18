module Admin
    class PromisesController < ApplicationController
      def index
        base_query = Promise.all

        # Server-side filters like Firestore
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

        # Client-side searchText logic (optional to move here)
        if params[:search].present?
          query = "%#{params[:search]}%"
          base_query = base_query.where("title ILIKE :q OR description ILIKE :q", q: query)
        end

        total = base_query.count
        promises = base_query.order(created_at: :desc)
                            .limit(params[:limit] || 25)
                            .offset(params[:offset] || 0)

      render json: {
        data: promises.as_json(only: [
          :id,
          :text,
          :source_type,
          :bc_promise_rank,
          :bc_promise_direction,
          :responsible_department_lead,
          :progress_score,
          :status,
          :evidence_ids
        ]),
        meta: { total: total }
      }
      end
    end
  end
