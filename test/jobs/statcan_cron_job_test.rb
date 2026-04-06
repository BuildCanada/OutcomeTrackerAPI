require "test_helper"

class StatcanCronJobTest < ActiveJob::TestCase
  def setup
    # Remove fixture data before each test
    StatcanDataset.delete_all
  end

  test "should enqueue sync jobs for stale datasets only" do
    current_time = Time.utc(2025, 1, 2, 14, 0, 0)  # 2pm UTC

    # Create a stale dataset (never synced)
    stale_dataset1 = StatcanDataset.create!(
      name: "stale-never-synced",
      statcan_url: "https://statcan.gc.ca/stale1.csv",
      sync_schedule: "0 0 * * *",
      last_synced_at: nil
    )

    # Create another stale dataset (old sync)
    stale_dataset2 = StatcanDataset.create!(
      name: "stale-old-sync",
      statcan_url: "https://statcan.gc.ca/stale2.csv",
      sync_schedule: "0 0 * * *",
      last_synced_at: Time.utc(2025, 1, 1, 23, 0, 0)  # Yesterday 11pm UTC
    )

    # Create a fresh dataset (recent sync)
    _fresh_dataset = StatcanDataset.create!(
      name: "fresh-dataset",
      statcan_url: "https://statcan.gc.ca/fresh.csv",
      sync_schedule: "0 0 * * *",
      last_synced_at: Time.utc(2025, 1, 2, 1, 0, 0)  # 1am UTC today
    )

    # Track enqueued jobs
    assert_enqueued_jobs 2, only: StatcanSyncJob do
      StatcanCronJob.perform_now(current_time)
    end

    # Verify the correct jobs were enqueued
    assert_enqueued_with(job: StatcanSyncJob, args: [ stale_dataset1 ])
    assert_enqueued_with(job: StatcanSyncJob, args: [ stale_dataset2 ])
  end

  test "should not enqueue jobs when no datasets need syncing" do
    current_time = Time.parse("2025-01-02 14:00:00")

    # Create only fresh datasets
    StatcanDataset.create!(
      name: "fresh-dataset-1",
      statcan_url: "https://statcan.gc.ca/fresh1.csv",
      sync_schedule: "0 0 * * *",
      last_synced_at: Time.parse("2025-01-02 01:00:00")  # 1am today
    )

    # Should not enqueue any jobs
    assert_enqueued_jobs 0, only: StatcanSyncJob do
      StatcanCronJob.perform_now(current_time)
    end
  end
end
