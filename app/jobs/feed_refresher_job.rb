class FeedRefresherJob < ApplicationJob
  queue_as :default

  def perform(feed: nil)
    if feed.nil?
      Feed.find_each { |f| FeedRefresherJob.perform_later(feed: f) }
    else
      feed.refresh!
    end
  end
end
