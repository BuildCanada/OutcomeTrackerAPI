# Plan 6: Adding New Data Sources

## Goal

Add priority data source feeds to improve coverage for underserved commitment types (spending, diplomatic, institutional).

## Current Coverage Gaps

| Commitment Type | Coverage | Key Gap |
|---|---|---|
| `spending` | **Weak** | No budget/estimates feeds |
| `diplomatic` | **Weak** | No treaty/GAC feeds |
| `institutional` | **Medium** | No GIC appointments feed |
| `procedural` | **Medium** | Need OIC feed |
| `outcome` | **Medium** | Need StatCan-to-commitment mappings |

## Priority 1: Government News Feeds

These are RSS/Atom feeds that work with the existing `Feed` + `FeedRefresherJob` infrastructure. No code changes needed -- just create Feed records.

### Seed File: `db/seeds/feeds_priority_1.rb`

```ruby
government = Government.find_by!(slug: "federal")

feeds = [
  {
    title: "Orders in Council",
    url: "https://orders-in-council.canada.ca/results.php?lang=en&format=rss",
    description: "Federal Orders in Council - covers procedural and institutional commitments"
  },
  {
    title: "Department of Finance News",
    url: "https://www.canada.ca/en/department-finance/news.atom",
    description: "Finance Canada news releases - budget, estimates, fiscal documents"
  },
  {
    title: "Prime Minister's Office News",
    url: "https://www.canada.ca/en/prime-minister/news.atom",
    description: "PM announcements covering all commitment types"
  },
  {
    title: "Department of National Defence News",
    url: "https://www.canada.ca/en/department-national-defence/news.atom",
    description: "DND news - defence spending and procurement commitments"
  },
  {
    title: "Immigration, Refugees and Citizenship News",
    url: "https://www.canada.ca/en/immigration-refugees-citizenship/news.atom",
    description: "IRCC news - immigration and refugee commitments"
  },
  {
    title: "Innovation, Science and Economic Development News",
    url: "https://www.canada.ca/en/innovation-science-economic-development/news.atom",
    description: "ISED news - economy, AI, innovation commitments"
  },
  {
    title: "Indigenous Services Canada News",
    url: "https://www.canada.ca/en/indigenous-services-canada/news.atom",
    description: "ISC news - Indigenous commitments"
  },
  {
    title: "Crown-Indigenous Relations News",
    url: "https://www.canada.ca/en/crown-indigenous-relations-northern-affairs/news.atom",
    description: "CIRNAC news - Indigenous reconciliation commitments"
  },
  {
    title: "Environment and Climate Change News",
    url: "https://www.canada.ca/en/environment-climate-change/news.atom",
    description: "ECCC news - environment and climate commitments"
  },
  {
    title: "Canada Mortgage and Housing Corporation News",
    url: "https://www.canada.ca/en/canada-mortgage-housing-corporation/news.atom",
    description: "CMHC news - housing commitments"
  },
  {
    title: "Health Canada News",
    url: "https://www.canada.ca/en/health-canada/news.atom",
    description: "Health Canada news - healthcare commitments"
  },
  {
    title: "Global Affairs Canada News",
    url: "https://www.canada.ca/en/global-affairs/news.atom",
    description: "GAC news - diplomatic commitments"
  },
  {
    title: "Treasury Board Secretariat News",
    url: "https://www.canada.ca/en/treasury-board-secretariat/news.atom",
    description: "TBS news - procedural and spending commitments"
  },
  {
    title: "Veterans Affairs Canada News",
    url: "https://www.canada.ca/en/veterans-affairs-canada/news.atom",
    description: "VAC news - veterans commitments"
  }
]

feeds.each do |feed_data|
  Feed.find_or_create_by!(government: government, url: feed_data[:url]) do |f|
    f.title = feed_data[:title]
    f.description = feed_data[:description]
  end
end

puts "Created #{feeds.size} priority 1 feeds"
```

## Priority 2: StatCan Indicator Mappings

Map specific Statistics Canada tables to outcome commitments. Create StatcanDataset records that will be automatically synced.

### Seed File: `db/seeds/statcan_commitment_mappings.rb`

```ruby
# Key StatCan datasets for commitment tracking
datasets = [
  {
    name: "defence-spending-gdp",
    statcan_url: "https://www150.statcan.gc.ca/t1/tbl1/en/dtl!downloadTbl/en/TV/...",
    sync_schedule: "0 6 * * 1", # Weekly Monday 6am
    description: "Defence spending as % of GDP - for defence spending commitment"
  },
  {
    name: "housing-starts",
    statcan_url: "https://www150.statcan.gc.ca/t1/tbl1/en/dtl!downloadTbl/en/TV/...",
    sync_schedule: "0 6 1 * *", # Monthly 1st at 6am
    description: "Housing starts - for housing construction commitments"
  },
  {
    name: "immigration-levels",
    statcan_url: "https://www150.statcan.gc.ca/t1/tbl1/en/dtl!downloadTbl/en/TV/...",
    sync_schedule: "0 6 1 * *",
    description: "Immigration levels by category - for immigration commitments"
  },
  {
    name: "childcare-spaces",
    statcan_url: "https://www150.statcan.gc.ca/t1/tbl1/en/dtl!downloadTbl/en/TV/...",
    sync_schedule: "0 6 1 * *",
    description: "Childcare enrollment and spaces - for childcare expansion commitments"
  }
]

# NOTE: StatCan URLs need to be validated and corrected to actual CSV download endpoints
# The URLs above are placeholders - each needs the actual table number and download URL
# from https://www150.statcan.gc.ca/

datasets.each do |data|
  StatcanDataset.find_or_create_by!(name: data[:name]) do |ds|
    ds.statcan_url = data[:statcan_url]
    ds.sync_schedule = data[:sync_schedule]
  end
rescue => e
  puts "Skipping #{data[:name]}: #{e.message}"
end
```

**Note:** The actual StatCan CSV download URLs need to be researched and validated. The URLs above are placeholders.

## Priority 3: Future Sources (No Implementation Now)

These require custom scrapers or manual processes:

| Source | Notes |
|---|---|
| Departmental Results Reports | Annual PDFs - could use Plan 1's PDF extraction pipeline |
| GAC Treaty Database | `treaty-accord.gc.ca` - may need custom scraper |
| Parliamentary Budget Officer | `pbo-dpb.gc.ca` - reports as PDFs, could use Plan 1 |
| Public Accounts | Annual, manual Source entry in Avo |
| Main Estimates | TBS publications, PDF extraction |

## Files to Create

| File | Purpose |
|---|---|
| `db/seeds/feeds_priority_1.rb` | Government department news feeds |
| `db/seeds/statcan_commitment_mappings.rb` | StatCan dataset registrations |

## Files to Modify

| File | Change |
|---|---|
| `db/seeds.rb` | Add `require` for new seed files |

## Verification

1. Run seeds: `rails db:seed`
2. Verify ~14 new Feed records created
3. Manually trigger `FeedRefresherJob.perform_now` on one feed
4. Verify entries are created from the feed
5. If Plan 4 is implemented, verify new entries flow through relevance filtering
6. Verify StatCan datasets are registered (pending URL validation)

## URL Validation Task

Before running the feeds seed, validate each RSS/Atom URL:
- Fetch each URL and confirm it returns valid RSS/Atom XML
- Some government URLs may have changed format or require different paths
- The `orders-in-council.canada.ca` RSS URL needs specific verification
