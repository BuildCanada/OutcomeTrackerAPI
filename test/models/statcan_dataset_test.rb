require "test_helper"

class StatcanDatasetTest < ActiveSupport::TestCase
  def self.valid_attributes
    {
      statcan_url: "https://www150.statcan.gc.ca/t1/tbl1/en/tv.action?pid=1410028701",
      name: "demographic-incomes",
      sync_schedule: "0 6 * * *"
    }
  end


  test "valid dataset" do
    dataset = StatcanDataset.new(self.class.valid_attributes)

    assert dataset.valid?
  end

  test "requires statcan_url" do
    attributes = self.class.valid_attributes.except(:statcan_url)
    dataset = StatcanDataset.new(attributes)

    assert_not dataset.valid?
    assert_includes dataset.errors[:statcan_url], "can't be blank"
  end

  test "requires name" do
    attributes = self.class.valid_attributes.except(:name)
    dataset = StatcanDataset.new(attributes)

    assert_not dataset.valid?
    assert_includes dataset.errors[:name], "can't be blank"
  end

  test "requires sync_schedule" do
    attributes = self.class.valid_attributes.except(:sync_schedule)
    dataset = StatcanDataset.new(attributes)

    assert_not dataset.valid?
    assert_includes dataset.errors[:sync_schedule], "can't be blank"
  end

  test "statcan_url must be unique" do
    url = "https://www150.statcan.gc.ca/t1/tbl1/en/tv.action?pid=1410028701"

    StatcanDataset.create!(
      statcan_url: url,
      name: "first-dataset",
      sync_schedule: "0 6 * * *"
    )

    duplicate = StatcanDataset.new(
      statcan_url: url,
      name: "second-dataset",
      sync_schedule: "0 12 * * *"
    )

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:statcan_url], "has already been taken"
  end

  test "name must be unique" do
    name = "demographic-incomes"

    StatcanDataset.create!(
      statcan_url: "https://www150.statcan.gc.ca/t1/tbl1/en/tv.action?pid=1410028701",
      name: name,
      sync_schedule: "0 6 * * *"
    )

    duplicate = StatcanDataset.new(
      statcan_url: "https://different-url.statcan.gc.ca/data",
      name: name,
      sync_schedule: "0 12 * * *"
    )

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:name], "has already been taken"
  end

  test "name must be kebab-case" do
    attributes = self.class.valid_attributes.merge(name: "InvalidName")
    dataset = StatcanDataset.new(attributes)

    assert_not dataset.valid?
    assert_includes dataset.errors[:name], "must be lowercase with hyphens only"
  end

  test "sync_schedule accepts valid cron expressions" do
    valid_schedules = [ "0 6 * * *", "30 14 1 * *", "0 * * * 0", "15 9 * * 1-5" ]

    valid_schedules.each do |schedule|
      attributes = self.class.valid_attributes.merge(sync_schedule: schedule, name: "test-dataset-#{schedule.hash}")
      dataset = StatcanDataset.new(attributes)

      assert dataset.valid?, "#{schedule} should be valid"
    end
  end

  test "sync_schedule rejects invalid cron expressions" do
    invalid_schedules = [ "invalid", "60 25 32 13 8", "not a cron" ]

    invalid_schedules.each do |schedule|
      attributes = self.class.valid_attributes.merge(name: "test-dataset-#{schedule.hash}", sync_schedule: schedule)
      dataset = StatcanDataset.new(attributes)

      assert_not dataset.valid?, "#{schedule} should be invalid"
      assert_includes dataset.errors[:sync_schedule], "must be a valid cron expression"
    end
  end

  test "needs_sync returns true when last_synced_at is nil" do
   attributes = self.class.valid_attributes.merge(last_synced_at: nil)
   dataset = StatcanDataset.new(attributes)
   current_time = Time.parse("2025-01-02 14:00:00")

   assert dataset.needs_sync?(current_time)
  end

  test "needs_sync returns true when last sync was before last scheduled time" do
   attributes = self.class.valid_attributes.merge(sync_schedule: "0 0 * * *", last_synced_at: Time.parse("2025-01-01 23:00:00"))
   dataset = StatcanDataset.new(attributes)
   current_time = Time.parse("2025-01-02 14:00:00")  # 2pm next day

   assert dataset.needs_sync?(current_time)
  end

  test "needs_sync returns false when last sync was after last scheduled time" do
    attributes = self.class.valid_attributes.merge(sync_schedule: "0 0 * * *", last_synced_at: Time.parse("2025-01-02 01:00:00"))
    dataset = StatcanDataset.new(attributes)
    current_time = Time.parse("2025-01-02 14:00:00")  # 2pm same day

    assert_not dataset.needs_sync?(current_time)
  end

  test "filter_stale returns datasets that need syncing" do
   stale_attributes = self.class.valid_attributes.merge(last_synced_at: nil)
   stale_dataset = StatcanDataset.new(stale_attributes)

   fresh_attributes = self.class.valid_attributes.merge(sync_schedule: "0 0 * * *", last_synced_at: Time.parse("2025-01-02 01:00:00"))
   fresh_dataset = StatcanDataset.new(fresh_attributes)

   current_time = Time.parse("2025-01-02 14:00:00")  # 2pm same day
   all_datasets = [ stale_dataset, fresh_dataset ]
   stale_datasets = StatcanDataset.filter_stale(all_datasets, current_time)

   assert_includes stale_datasets, stale_dataset
   assert_not_includes stale_datasets, fresh_dataset
   assert_equal 1, stale_datasets.length
 end

  test "filter_stale works with empty collection" do
    stale_datasets = StatcanDataset.filter_stale([])
    assert_empty stale_datasets
  end

  test "sync! should update dataset with fetched data" do
    dataset = statcan_datasets(:unsynced)
    parsed_data = [ { "population" => 1000000, "year" => 2023 } ]

    StatcanFetcher.stub :fetch, parsed_data do
      dataset.sync!
    end

    dataset.reload
    assert_equal parsed_data, dataset.current_data
    assert_not_nil dataset.last_synced_at
  end

  test "sync! should not update dataset when fetch times out" do
    dataset = statcan_datasets(:unsynced)

    StatcanFetcher.stub :fetch, ->(url) { raise HTTP::TimeoutError.new("Request timed out") } do
      assert_raises HTTP::TimeoutError do
        dataset.sync!
      end
    end

    dataset.reload
    assert_nil dataset.current_data
  end
end
