class FeedItemsController < ApplicationController
  def index
    scope = params[:commitment_id] ? FeedItem.where(commitment_id: params[:commitment_id]) : FeedItem.all

    @feed_items = scope
      .newest_first
      .by_event_type(params[:event_type])
      .by_policy_area(params[:policy_area_id])
      .since(params[:since])
      .until_date(params[:until])
      .includes(:commitment, :policy_area)

    @feed_items = @feed_items.limit(page_size).offset(page_offset)

    respond_to do |format|
      format.json { render json: feed_items_json }
      format.rss { render_rss }
    end
  end

  private

  def page_size
    [(params[:per_page] || 50).to_i, 100].min
  end

  def page_offset
    [(params[:page] || 1).to_i - 1, 0].max * page_size
  end

  def feed_items_json
    {
      feed_items: @feed_items.map { |fi| serialize_feed_item(fi) },
      meta: { page: (params[:page] || 1).to_i, per_page: page_size }
    }
  end

  def serialize_feed_item(fi)
    {
      id: fi.id,
      event_type: fi.event_type,
      title: fi.title,
      summary: fi.summary,
      occurred_at: fi.occurred_at.iso8601,
      commitment: {
        id: fi.commitment_id,
        title: fi.commitment.title
      },
      policy_area: fi.policy_area ? { id: fi.policy_area.id, name: fi.policy_area.name } : nil
    }
  end

  def render_rss
    builder = Builder::XmlMarkup.new(indent: 2)
    builder.instruct! :xml, version: "1.0"

    xml = builder.rss(version: "2.0") do |rss|
      rss.channel do |channel|
        channel.title "Commitment Tracker Feed"
        channel.description "Activity feed for government commitment tracking"
        channel.link request.url

        @feed_items.each do |fi|
          channel.item do |item|
            item.title fi.title
            item.description fi.summary
            item.pubDate fi.occurred_at.rfc2822
            item.guid "feed-item-#{fi.id}"
            item.category fi.event_type
          end
        end
      end
    end

    render xml: xml, content_type: "application/rss+xml"
  end
end
