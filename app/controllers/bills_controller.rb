class BillsController < ApplicationController
  before_action :set_bill, only: %i[ show ]

  # GET /bills
  def index
    @bills = Bill.all
    @bills = @bills.where(parliament_number: params[:parliament_number]) if params[:parliament_number].present?
    @bills = @bills.government_bills if params[:government_bills] == "true"

    render json: @bills
  end

  # GET /bills/1
  def show
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_bill
      @bill = Bill.find(params.expect(:id))
    end
end
