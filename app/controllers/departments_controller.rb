class DepartmentsController < ApplicationController
  before_action :set_department, only: %i[ show ]

  # GET /departments`
  def index
    @departments = Department.includes(:minister).order(:display_name)
    render json: @departments.map { |dept|
      minister_json = if dept.minister
        hill = dept.minister.contact_data&.dig("offices")&.find { |o| o["type"]&.match?(/hill/i) }
        dept.minister.as_json(only: [ :first_name, :last_name, :title, :avatar_url, :email, :phone, :website, :constituency, :province ]).merge(
          "hill_office" => hill
        )
      end
      dept.as_json(only: [ :id, :display_name, :slug, :priority, :official_name ]).merge(
        "minister" => minister_json
      )
    }
  end

  # GET /departments/1
  def show
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_department
      id = params.expect(:id)
      if id.match(/[0-9]/)
        @department = Department.find(id)
      else
        @department = Department.find_by(slug: id)
      end
    end
end
