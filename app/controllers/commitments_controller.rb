class CommitmentsController < ApplicationController
  def index
    @commitments = Commitment.all
    render json: @commitments
  end

  def show
    @commitment = Commitment.find(params[:id])
  end
end
