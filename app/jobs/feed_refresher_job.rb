class FeedRefresherJob < ApplicationJob
  queue_as :default

  def perform(feed = nil)
    if feed.nil?
      Feed.all.each { |f| FeedRefresherJob.perform_later(f) }
    else
      feed.refresh!
    end
  end
end
