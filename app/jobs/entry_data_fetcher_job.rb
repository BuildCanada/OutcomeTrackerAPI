class EntryDataFetcherJob < ApplicationJob
  queue_as :default

  def perform(entry)
    entry.fetch_data!(inline: true)
    # Do something later
  end
end
