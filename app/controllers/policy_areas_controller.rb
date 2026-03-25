class PolicyAreasController < ApplicationController
  def index
    render json: PolicyArea.ordered.as_json(only: [ :id, :name, :slug, :description, :position ])
  end
end
