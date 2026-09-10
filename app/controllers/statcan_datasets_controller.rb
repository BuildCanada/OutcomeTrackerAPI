class StatcanDatasetsController < ApplicationController
  def show
    dataset = StatcanDataset.find_by(name: params[:id]) || StatcanDataset.find_by(id: params[:id])

    if dataset
      render json: dataset
    else
      render json: { error: "Dataset not found" }, status: :not_found
    end
  end
end
