module Admin
  class DashboardController < ApplicationController
    skip_before_action :verify_authenticity_token

    def scraping_health
      unscraped_entries = Entry.where(scraped_at: nil, skipped_at: nil)

      feeds_breakdown = unscraped_entries
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

      unscraped_details = unscraped_entries
        .includes(:feed)
        .order(created_at: :desc)
        .limit(100)
        .map do |entry|
          {
            id: entry.id,
            title: entry.title,
            url: entry.url,
            feed_title: entry.feed.title,
            created_at: entry.created_at,
            published_at: entry.published_at
          }
        end

      render json: {
        total_unscraped: unscraped_entries.count,
        by_feed: feeds_breakdown,
        recent_unscraped: unscraped_details
      }
    end

    def requeue
      entry_ids = params[:entry_ids]

      unless entry_ids.is_a?(Array) && entry_ids.any?
        return render json: { error: "entry_ids must be a non-empty array" }, status: :unprocessable_entity
      end

      entries = Entry.where(id: entry_ids, scraped_at: nil, skipped_at: nil)
      queued_ids = entries.pluck(:id)

      entries.each do |entry|
        EntryDataFetcherJob.perform_later(entry)
      end

      render json: {
        queued: queued_ids.size,
        entry_ids: queued_ids
      }
    end
  end
end
