class DepartmentsController < ApplicationController
  before_action :set_department, only: %i[ show ]

  # GET /departments`
  def index
    @departments = Department.order(:display_name)
    render json: @departments.as_json(only: [:id, :display_name, :slug, :priority, :official_name])
  end

  # GET /departments/1
  def show
    render json: @department
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_department
      @department = Department.find(params.expect(:id))
    end
end
