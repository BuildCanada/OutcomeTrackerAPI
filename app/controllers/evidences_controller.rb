class EvidencesController < ApplicationController
  before_action :set_evidence, only: %i[ show ]

  # GET /evidences
  def index
    @evidences = Evidence.all

    render json: @evidences
  end

  # GET /evidences/1
  def show
    render json: @evidence
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_evidence
      @evidence = Evidence.find(params.expect(:id))
    end
end
