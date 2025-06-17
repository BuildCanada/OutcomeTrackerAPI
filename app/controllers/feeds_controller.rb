class FeedsController < ApplicationController
  before_action :set_feed, only: %i[ show ]

  # GET /feeds
  def index
    @feeds = Feed.all

    render json: @feeds
  end

  # GET /feeds/1
  def show
    render json: @feed
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_feed
      @feed = Feed.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def feed_params
      params.expect(feed: [ :title, :description, :language, :url, :last_scraped, :raw, :government_id ])
    end
end
