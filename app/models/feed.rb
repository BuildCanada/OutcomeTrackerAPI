class Feed < ApplicationRecord
  belongs_to :government

  has_many :entries, dependent: :destroy

  def refresh!
    # Implement the logic to refresh the feed data
    response = HTTP.get(url)

    raw_feed = Feedjira.parse(response.body.to_s)
    title = raw_feed.title
    description = raw_feed.description

    # This will often be the upstream url of the publication rather than the feed itself
    source_url = raw_feed.url

    self.raw = JSON.parse(raw_feed.to_json).except("entries")

    create_entries!(raw_feed.entries)
  end

  def create_entries!(entries)
    entries.each do |entry|
      raise "URL is required" unless entry.url.present?
      Entry.find_or_create_by!(government: government, feed: self, url: entry.url) do |rec|
        rec.title = entry.title
        rec.summary = entry.summary
        rec.published_at = entry.published
        rec.raw = entry.to_json
      end
    end
  end
end
