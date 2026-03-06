class CommitmentsController < ApplicationController
  def index
    @commitments = Commitment.includes(:policy_area, :lead_department)

    @commitments = @commitments.search(params[:q]) if params[:q].present?
    @commitments = @commitments.where(policy_area_id: params[:policy_area_id]) if params[:policy_area_id].present?
    @commitments = @commitments.where(status: params[:status]) if params[:status].present?
    @commitments = @commitments.where(commitment_type: params[:commitment_type]) if params[:commitment_type].present?
    @commitments = @commitments.where(party_code: params[:party_code]) if params[:party_code].present?
    @commitments = @commitments.where(region_code: params[:region_code]) if params[:region_code].present?

    if params[:department_id].present?
      @commitments = @commitments.joins(:commitment_departments).where(commitment_departments: { department_id: params[:department_id] })
    end

    @commitments = apply_sorting(@commitments)
    @total_count = @commitments.count
    @commitments = @commitments.limit(page_size).offset(page_offset)
  end

  def show
    @commitment = Commitment.find(params[:id])
  end

  private

  def apply_sorting(scope)
    case params[:sort]
    when "title" then scope.order(title: sort_direction)
    when "date_promised" then scope.order(date_promised: sort_direction)
    when "last_assessed_at" then scope.order(last_assessed_at: sort_direction)
    when "status" then scope.order(status: sort_direction)
    else scope.order(created_at: :desc)
    end
  end

  def sort_direction
    params[:direction] == "asc" ? :asc : :desc
  end

  def page_size
    [(params[:per_page] || 50).to_i, 100].min
  end

  def page_offset
    [(params[:page] || 1).to_i - 1, 0].max * page_size
  end
end
