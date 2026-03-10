class EntryDataFetcherJob < ApplicationJob
  queue_as :default

  retry_on HTTP::TimeoutError, wait: 30.seconds, attempts: 3
  discard_on ActiveJob::DeserializationError

  def perform(entry)
    entry.fetch_data!(inline: true)
  end
end
