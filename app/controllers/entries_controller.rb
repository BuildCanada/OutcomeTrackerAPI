class EntriesController < ApplicationController
  before_action :set_entry, only: %i[ show ]

  # GET /entries
  def index
    @entries = Entry.all

    render json: @entries
  end

  # GET /entries/1
  def show
    render json: @entry
  end


  private
    # Use callbacks to share common setup or constraints between actions.
    def set_entry
      @entry = Entry.find(params.expect(:id))
    end
end
