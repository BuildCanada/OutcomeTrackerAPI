class EntryDataFetcherJob < ApplicationJob
  queue_as :default

  def perform(entry)
    entry.fetch_data!(in_background: false)
    # Do something later
  end
end
