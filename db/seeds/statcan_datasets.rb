puts "Seeding StatcanDatasets..."

statcan_datasets = [
  {
    name: "balance-sheets",
    statcan_url: "https://www150.statcan.gc.ca/t1/tbl1/en/dtl!downloadDbLoadingData-nonTraduit.action?pid=1010001501&latestN=0&startDate=19901001&endDate=&csvLocale=en&selectedMembers=%5B%5B1%5D%2C%5B2%5D%2C%5B%5D%5D&checkedLevels=2D1%2C2D2%2C2D3",
    sync_schedule: "23 6 * * *" # Daily at 6:23 AM
  },
  {
    name: "demographic-incomes-non-permanent-residents",
    statcan_url: "https://www150.statcan.gc.ca/t1/tbl1/en/dtl!downloadDbLoadingData-nonTraduit.action?pid=1110009101&latestN=2&startDate=&endDate=&csvLocale=en&selectedMembers=%5B%5B1%5D%2C%5B%5D%2C%5B%5D%2C%5B%5D%2C%5B5%5D%5D&checkedLevels=1D1%2C1D2%2C1D3%2C2D1%2C3D1",
    sync_schedule: "23 8 * * *" # Daily at 8:23 AM
  },
  {
    name: "gdp",
    statcan_url: "https://www150.statcan.gc.ca/t1/tbl1/en/dtl!downloadDbLoadingData-nonTraduit.action?pid=3610010401&latestN=0&startDate=19610101&endDate=&csvLocale=en&selectedMembers=%5B%5B1%5D%2C%5B1%5D%2C%5B1%5D%2C%5B%5D%5D&checkedLevels=3D1%2C3D2%2C3D3%2C3D4",
    sync_schedule: "23 6 * * *" # Daily at 6:23 AM
  },
  {
    name: "housing-starts",
    statcan_url: "https://www150.statcan.gc.ca/t1/tbl1/en/dtl!downloadDbLoadingData.action?pid=3410015101&latestN=0&startDate=19880101&endDate=&csvLocale=en&selectedMembers=%5B%5B%5D%2C%5B1%5D%2C%5B%5D%5D&checkedLevels=0D1%2C2D1%2C2D2",
    sync_schedule: "23 6 * * *" # Daily at 6:23 AM
  },
  {
    name: "labour-productivity",
    statcan_url: "https://www150.statcan.gc.ca/t1/tbl1/en/dtl!downloadDbLoadingData-nonTraduit.action?pid=3610020701&latestN=0&startDate=19801001&endDate=&csvLocale=en&selectedMembers=%5B%5B1%5D%2C%5B5%5D%2C%5B1%2C2%2C3%2C4%2C5%2C6%2C7%2C8%2C9%2C10%2C11%2C13%2C14%2C15%2C16%2C17%2C18%2C19%2C20%2C21%5D%5D&checkedLevels=",
    sync_schedule: "23 9 * * *" # Daily at 9:23 AM
  },
  {
    name: "non-permanent-residents",
    statcan_url: "https://www150.statcan.gc.ca/t1/tbl1/en/dtl!downloadDbLoadingData.action?pid=1710012101&latestN=0&startDate=20210101&endDate=&csvLocale=en&selectedMembers=%5B%5B%5D%2C%5B%5D%5D&checkedLevels=0D1%2C1D1%2C1D2%2C1D3",
    sync_schedule: "23 7 * * *" # Daily at 7:23 AM
  },
  {
    name: "population",
    statcan_url: "https://www150.statcan.gc.ca/t1/tbl1/en/dtl!downloadDbLoadingData-nonTraduit.action?pid=1710000901&latestN=0&startDate=19000101&endDate=&csvLocale=en&selectedMembers=%5B%5B1%2C2%2C3%2C4%2C5%2C6%2C7%2C8%2C9%2C10%2C11%2C12%2C14%2C15%5D%5D&checkedLevels=",
    sync_schedule: "23 6 * * *" # Daily at 6:23 AM
  },
  {
    name: "primary-energy-production",
    statcan_url: "https://www150.statcan.gc.ca/t1/tbl1/en/dtl!downloadDbLoadingData-nonTraduit.action?pid=2510007901&latestN=5&startDate=&endDate=&csvLocale=en&selectedMembers=%5B%5B%5D%2C%5B%5D%2C%5B%5D%5D&checkedLevels=0D1%2C1D1%2C1D2%2C1D3%2C2D1",
    sync_schedule: "23 10 * * *" # Daily at 10:23 AM
  }
]

statcan_datasets.each do |dataset_attrs|
  dataset = StatcanDataset.find_or_create_by(name: dataset_attrs[:name]) do |d|
    d.statcan_url = dataset_attrs[:statcan_url]
    d.sync_schedule = dataset_attrs[:sync_schedule]
  end

  if dataset.persisted?
    if dataset.previously_new_record?
      puts "✓ #{dataset.name} - created"
    else
      puts "✓ #{dataset.name} - already exists"
    end
  else
    puts "✗ #{dataset.name} - failed to create: #{dataset.errors.full_messages.join(', ')}"
  end
end
