class StatcanSyncJob < ApplicationJob
  queue_as :default

  def perform(statcan_dataset)
    statcan_dataset.sync!
  end
end


## Job Sync Update for Statcan Dataset
rows = StatcanDataset.limit(10_000).map do |d|
  {
    dataset_id: d.dataset_id,
    table_id:   d.table_id,
    title:      d.title,
    frequency:  d.frequency,
    ref_date:   d.ref_date&.iso8601,
    value:      d.value,
    unit:       d.unit,
    geo:        d.geo,
    updated_at: d.updated_at.iso8601,
    source:     "statcan"
  }.compact
end

Lake::Writer.write_jsonl(rows: rows, dest_prefix: "statcan", partition_dt: Date.today)

