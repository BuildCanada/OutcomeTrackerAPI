class BillsController < ApplicationController
  before_action :set_bill, only: %i[ show ]

  # GET /bills
  def index
    @bills = Bill.all

    render json: @bills
  end

  # GET /bills/1
  def show
    render json: @bill
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_bill
      @bill = Bill.find(params.expect(:id))
    end
end
