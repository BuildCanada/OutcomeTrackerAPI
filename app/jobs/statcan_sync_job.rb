class StatcanSyncJob < ApplicationJob
  queue_as :default

  def perform(statcan_dataset)
    statcan_dataset.sync!
  end
end
