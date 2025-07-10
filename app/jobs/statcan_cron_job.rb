class StatcanCronJob < ApplicationJob
  queue_as :default

  def perform(current_time = Time.current)
    datasets = StatcanDataset.select(:id, :sync_schedule, :last_synced_at)
    stale_datasets = StatcanDataset.filter_stale(datasets, current_time)
    stale_datasets.each(&StatcanSyncJob.method(:perform_later))

    Rails.logger.info "Enqueued #{stale_datasets.count} Statcan sync jobs"
  end
end
