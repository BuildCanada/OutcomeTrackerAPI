require "test_helper"

class CommitmentRelevanceFilterJobTest < ActiveJob::TestCase
  setup do
    @government = governments(:canada)
    @feed = feeds(:canada_gazette)
  end

  test "excludes commitments promised after the entry was published" do
    commitment = Commitment.create!(
      government: @government,
      title: "Future commitment",
      description: "Made after entry was published",
      commitment_type: :spending,
      status: :not_started,
      date_promised: Date.new(2025, 6, 1)
    )

    entry = Entry.new(
      feed: @feed,
      government: @government,
      title: "Old entry",
      url: "http://example.com/old-entry",
      published_at: Date.new(2025, 5, 1)
    )
    entry.save!(validate: true)

    job = CommitmentRelevanceFilterJob.new
    result = job.send(:active_commitments_for, entry)

    assert_not_includes result.to_a, commitment
  end

  test "includes commitments promised before the entry was published" do
    commitment = Commitment.create!(
      government: @government,
      title: "Earlier commitment",
      description: "Made before entry was published",
      commitment_type: :spending,
      status: :not_started,
      date_promised: Date.new(2025, 4, 1)
    )

    entry = Entry.new(
      feed: @feed,
      government: @government,
      title: "Later entry",
      url: "http://example.com/later-entry",
      published_at: Date.new(2025, 5, 1)
    )
    entry.save!(validate: true)

    job = CommitmentRelevanceFilterJob.new
    result = job.send(:active_commitments_for, entry)

    assert_includes result.to_a, commitment
  end

  test "includes commitments promised on the same day the entry was published" do
    commitment = Commitment.create!(
      government: @government,
      title: "Same-day commitment",
      description: "Made on the same day",
      commitment_type: :spending,
      status: :not_started,
      date_promised: Date.new(2025, 5, 1)
    )

    entry = Entry.new(
      feed: @feed,
      government: @government,
      title: "Same-day entry",
      url: "http://example.com/same-day-entry",
      published_at: Date.new(2025, 5, 1)
    )
    entry.save!(validate: true)

    job = CommitmentRelevanceFilterJob.new
    result = job.send(:active_commitments_for, entry)

    assert_includes result.to_a, commitment
  end

  test "falls back to created_at when date_promised is nil" do
    commitment = Commitment.create!(
      government: @government,
      title: "No date_promised commitment",
      description: "No date_promised set",
      commitment_type: :spending,
      status: :not_started,
      date_promised: nil
    )
    # created_at is set to now, which is after our entry's published_at
    commitment.update_columns(created_at: Time.new(2025, 7, 1))

    entry = Entry.new(
      feed: @feed,
      government: @government,
      title: "Entry before commitment created",
      url: "http://example.com/before-created",
      published_at: Date.new(2025, 5, 1)
    )
    entry.save!(validate: true)

    job = CommitmentRelevanceFilterJob.new
    result = job.send(:active_commitments_for, entry)

    assert_not_includes result.to_a, commitment
  end

  test "excludes abandoned commitments regardless of date" do
    commitment = Commitment.create!(
      government: @government,
      title: "Abandoned commitment",
      description: "This was abandoned",
      commitment_type: :spending,
      status: :abandoned,
      date_promised: Date.new(2025, 1, 1)
    )

    entry = Entry.new(
      feed: @feed,
      government: @government,
      title: "Entry",
      url: "http://example.com/abandoned-test",
      published_at: Date.new(2025, 12, 1)
    )
    entry.save!(validate: true)

    job = CommitmentRelevanceFilterJob.new
    result = job.send(:active_commitments_for, entry)

    assert_not_includes result.to_a, commitment
  end

  test "skips temporal filter for statcan datasets" do
    commitment = Commitment.create!(
      government: @government,
      title: "Any commitment",
      description: "Should match statcan regardless of date",
      commitment_type: :spending,
      status: :not_started,
      date_promised: Date.new(2025, 6, 1)
    )

    dataset = StatcanDataset.create!(
      name: "test-dataset",
      statcan_url: "https://statcan.gc.ca/test.csv",
      sync_schedule: "0 0 * * *"
    )

    job = CommitmentRelevanceFilterJob.new
    result = job.send(:active_commitments_for, dataset)

    assert_includes result.to_a, commitment
  end
end
