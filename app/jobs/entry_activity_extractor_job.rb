class EntryActivityExtractorJob < ApplicationJob
  queue_as :default

  def perform(entry)
    entry.extract_activities!(inline: true)
  end
end
