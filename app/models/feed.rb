class Feed < ApplicationRecord
  belongs_to :government

  has_many :entries, dependent: :destroy

  def self.ransackable_attributes(auth_object = nil)
    [ "title" ]
  end

  def refresh!
    # Implement the logic to refresh the feed data
    response = HTTP.get(url)

    raw_feed = Feedjira.parse(response.body.to_s)
    title = raw_feed.title
    description = raw_feed.description

    # This will often be the upstream url of the publication rather than the feed itself
    source_url = raw_feed.url

    self.raw = JSON.parse(raw_feed.to_json).except("entries")
    self.last_scraped_at = Time.now
    self.last_scrape_failed_at = nil
    self.error_message = nil

    self.save!

    create_entries!(raw_feed.entries)
  rescue => e
    Rails.logger.error("Error refreshing feed: #{e.message}")
    self.last_scrape_failed_at = Time.now
    self.error_message = e.message
    self.save!
  end

  def create_entries!(entries)
    entries.each do |entry|
      raise "URL is required" unless entry.url.present?
      if Entry.where(url: entry.url).where.not(feed: self).exists?
        Rails.logger.info("Entry already exists for URL: #{entry.url} from a different feed, skipping")
        next
      end
      Entry.find_or_create_by!(government: government, feed: self, url: entry.url) do |rec|
        rec.title = entry.title
        rec.summary = entry.summary
        rec.published_at = entry.published
        rec.raw = entry.to_json
      end
    end
  end
end
