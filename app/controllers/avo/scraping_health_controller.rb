class Avo::ScrapingHealthController < Avo::ApplicationController
  def index
    @unscraped_entries = Entry.where(scraped_at: nil, skipped_at: nil)

    @feeds_breakdown = @unscraped_entries
      .joins(:feed)
      .group("feeds.id", "feeds.title")
      .order("count_all DESC")
      .count
      .map do |(feed_id, feed_title), count|
        feed = Feed.find(feed_id)
        {
          feed_id: feed_id,
          feed_title: feed_title,
          unscraped_count: count,
          last_scraped_at: feed.last_scraped_at,
          last_scrape_failed_at: feed.last_scrape_failed_at,
          error_message: feed.error_message
        }
      end

    @entries = @unscraped_entries
      .includes(:feed)
      .order(created_at: :desc)
      .limit(100)
  end

  def requeue
    entry_ids = params[:entry_ids]

    unless entry_ids.is_a?(Array) && entry_ids.any?
      return redirect_to main_app.avo_scraping_health_index_path, alert: "No entries selected."
    end

    entries = Entry.where(id: entry_ids, scraped_at: nil, skipped_at: nil)

    entries.each do |entry|
      EntryDataFetcherJob.perform_later(entry)
    end

    redirect_to main_app.avo_scraping_health_index_path, notice: "Queued #{entries.count} entries for scraping."
  end
end
