namespace :lake do
  desc "Export Statcan data to the data lake"
  task export_statcan: :environment do
    dataset = StatcanDataset.first
    rows = dataset.current_data.map do |row|
      {
        dataset_id: dataset.id,
        table_id: row["TABLE_ID"],
        title: row["TITLE_EN"],
        frequency: row["FREQUENCY"],
        ref_date: row["REF_DATE"],
        value: row["VALUE"],
        unit: row["UOM"],
        geo: row["GEO"],
        updated_at: Time.current
      }
    end
    key = Lake::Writer.write_jsonl(rows, dt: Date.today, partition: "statcan")
    puts "Exported to #{key}"
  end
end