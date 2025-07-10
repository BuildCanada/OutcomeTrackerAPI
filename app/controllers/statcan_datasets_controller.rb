class StatcanDatasetsController < ApplicationController
  def show
    dataset = StatcanDataset.find(params[:id])
    render json: dataset
  end
end
