namespace :feeds do
  desc "Add Priority 1 & 2 data source feeds (Plan 7)"
  task add_priority_sources: :environment do
    government = Government.find_by!(slug: "federal")

    feeds = [
      {
        title: "Prime Minister Press Releases",
        url: "https://pm.gc.ca/en/rss.xml"
      },
      {
        title: "National Defence News Releases",
        url: "https://api.io.canada.ca/io-server/gc/news/en/v2?dept=departmentnationaldefense&type=newsreleases&sort=publishedDate&orderBy=desc&pick=100&format=atom&atomtitle=Canada%20News%20Centre%20-%20National%20Defence"
      },
      {
        title: "Immigration, Refugees and Citizenship Canada News Releases",
        url: "https://api.io.canada.ca/io-server/gc/news/en/v2?dept=departmentofcitizenshipandimmigration&type=newsreleases&sort=publishedDate&orderBy=desc&pick=100&format=atom&atomtitle=Canada%20News%20Centre%20-%20IRCC"
      },
      {
        title: "Indigenous Services Canada News Releases",
        url: "https://api.io.canada.ca/io-server/gc/news/en/v2?dept=indigenousservicescanada&type=newsreleases&sort=publishedDate&orderBy=desc&pick=100&format=atom&atomtitle=Canada%20News%20Centre%20-%20Indigenous%20Services%20Canada"
      },
      {
        title: "Innovation, Science and Economic Development News Releases",
        url: "https://api.io.canada.ca/io-server/gc/news/en/v2?dept=departmentofindustry&type=newsreleases&sort=publishedDate&orderBy=desc&pick=100&format=atom&atomtitle=Canada%20News%20Centre%20-%20ISED"
      },
      {
        title: "Global Affairs Canada News Releases",
        url: "https://api.io.canada.ca/io-server/gc/news/en/v2?dept=departmentofforeignaffairstradeanddevelopment&type=newsreleases&sort=publishedDate&orderBy=desc&pick=100&format=atom&atomtitle=Canada%20News%20Centre%20-%20Global%20Affairs%20Canada"
      },
      {
        title: "Health Canada News Releases",
        url: "https://api.io.canada.ca/io-server/gc/news/en/v2?dept=departmentofhealth&type=newsreleases&sort=publishedDate&orderBy=desc&pick=100&format=atom&atomtitle=Canada%20News%20Centre%20-%20Health%20Canada"
      },
      {
        title: "Environment and Climate Change Canada News Releases",
        url: "https://api.io.canada.ca/io-server/gc/news/en/v2?dept=departmentoftheenvironment&type=newsreleases&sort=publishedDate&orderBy=desc&pick=100&format=atom&atomtitle=Canada%20News%20Centre%20-%20Environment%20and%20Climate%20Change%20Canada"
      },
      {
        title: "Employment and Social Development Canada News Releases",
        url: "https://api.io.canada.ca/io-server/gc/news/en/v2?dept=departmentofemploymentandsocialdevelopment&type=newsreleases&sort=publishedDate&orderBy=desc&pick=100&format=atom&atomtitle=Canada%20News%20Centre%20-%20ESDC"
      },
      {
        title: "Transport Canada News Releases",
        url: "https://api.io.canada.ca/io-server/gc/news/en/v2?dept=departmentoftransport&type=newsreleases&sort=publishedDate&orderBy=desc&pick=100&format=atom&atomtitle=Canada%20News%20Centre%20-%20Transport%20Canada"
      },
      {
        title: "Natural Resources Canada News Releases",
        url: "https://api.io.canada.ca/io-server/gc/news/en/v2?dept=naturalresourcescanada&type=newsreleases&sort=publishedDate&orderBy=desc&pick=100&format=atom&atomtitle=Canada%20News%20Centre%20-%20Natural%20Resources%20Canada"
      },
      {
        title: "Treasury Board Secretariat News Releases",
        url: "https://api.io.canada.ca/io-server/gc/news/en/v2?dept=treasuryboardsecretariat&type=newsreleases&sort=publishedDate&orderBy=desc&pick=100&format=atom&atomtitle=Canada%20News%20Centre%20-%20Treasury%20Board%20Secretariat"
      },
      {
        title: "Crown-Indigenous Relations and Northern Affairs News Releases",
        url: "https://api.io.canada.ca/io-server/gc/news/en/v2?dept=crownindigenousrelationsandnorthernaffairscanada&type=newsreleases&sort=publishedDate&orderBy=desc&pick=100&format=atom&atomtitle=Canada%20News%20Centre%20-%20CIRNAC"
      },
      {
        title: "Parliamentary Budget Officer Reports",
        url: "https://www.pbo-dpb.ca/en/feed.xml"
      }
    ]

    created = 0
    skipped = 0

    feeds.each do |attrs|
      feed = Feed.find_or_create_by(url: attrs[:url], government: government) do |f|
        f.title = attrs[:title]
      end

      if feed.previously_new_record?
        created += 1
        puts "  Created: #{attrs[:title]}"
      else
        skipped += 1
      end
    end

    puts "\nDone. Created #{created} feeds, skipped #{skipped} (already existed)."
  end
end
