class StatcanDatasetsController < ApplicationController
  def show
    dataset = StatcanDataset.find_by(name: params[:id])
    if dataset
      render json: dataset
    else
      render json: { error: "Not found" }, status: :not_found
    end
  end
end
