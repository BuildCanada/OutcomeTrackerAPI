class CommitmentsController < ApplicationController
  def index
    @commitments = Commitment.includes(:policy_area, :lead_department)

    @commitments = @commitments.search(params[:q]) if params[:q].present?
    @commitments = @commitments.where(policy_area_id: params[:policy_area_id]) if params[:policy_area_id].present?
    @commitments = @commitments.joins(:policy_area).where(policy_areas: { slug: params[:policy_area] }) if params[:policy_area].present?
    @commitments = @commitments.where(status: params[:status]) if params[:status].present?
    @commitments = @commitments.where(commitment_type: params[:commitment_type]) if params[:commitment_type].present?
    @commitments = @commitments.where(party_code: params[:party_code]) if params[:party_code].present?
    @commitments = @commitments.where(region_code: params[:region_code]) if params[:region_code].present?

    if params[:department_id].present?
      @commitments = @commitments.joins(:commitment_departments).where(commitment_departments: { department_id: params[:department_id] })
    end

    if params[:department].present?
      @commitments = @commitments.joins(:commitment_departments).joins("INNER JOIN departments ON departments.id = commitment_departments.department_id").where(departments: { slug: params[:department] })
    end

    if params[:lead_department].present?
      @commitments = @commitments.joins(:lead_commitment_department).joins("INNER JOIN departments AS lead_depts ON lead_depts.id = commitment_departments.department_id").where(lead_depts: { slug: params[:lead_department] })
    end

    if params[:source_type].present?
      @commitments = @commitments.joins(:sources).where(sources: { source_type: params[:source_type] }).distinct
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
    [ (params[:per_page] || 50).to_i, 1000 ].min
  end

  def page_offset
    [ (params[:page] || 1).to_i - 1, 0 ].max * page_size
  end
end
