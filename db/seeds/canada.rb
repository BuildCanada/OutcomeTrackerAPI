government = Government.find_or_create_by!(name: "Government of Canada") do |g|
  g.slug = "federal"
end


departments_data = [
  { slug: "agriculture-and-agri-food-canada", priority: 2, display_name: "Agriculture", official_name: "Agriculture and Agri-Food Canada" },
  { slug: "artificial-intelligence-and-digital-innovation", priority: 1, display_name: "AI and Digital Innovation", official_name: "Artificial Intelligence and Digital Innovation" },
  { slug: "atlantic-canada-opportunities-agency", priority: 2, display_name: "Atlantic Canada Opportunities Agency", official_name: "Atlantic Canada Opportunities Agency" },
  { slug: "canada-economic-development-for-quebec-regions", priority: 2, display_name: "Canada Economic Development for Quebec", official_name: "Canada Economic Development for Quebec Regions" },
  { slug: "canada-revenue-agency", priority: 2, display_name: "Canada Revenue Agency", official_name: "Canada Revenue Agency" },
  { slug: "canadian-heritage", priority: 2, display_name: "Heritage", official_name: "Canadian Heritage" },
  { slug: "crown-indigenous-relations-and-northern-affairs-canada", priority: 2, display_name: "Crown-Indigenous Relations", official_name: "Crown-Indigenous Relations and Northern Affairs Canada" },
  { slug: "emergency-preparedness-canada", priority: 2, display_name: "Emergency Preparedness", official_name: "Emergency Preparedness Canada" },
  { slug: "employment-and-social-development-canada", priority: 2, display_name: "Jobs and Families", official_name: "Employment and Social Development Canada" },
  { slug: "environment-and-climate-change-canada", priority: 2, display_name: "Environment", official_name: "Environment and Climate Change Canada" },
  { slug: "federal-economic-development-agency-for-southern-ontario", priority: 2, display_name: "Federal Economic Development for Southern Ontario", official_name: "Federal Economic Development Agency for Southern Ontario" },
  { slug: "finance-canada", priority: 1, display_name: "Finance", official_name: "Finance Canada" },
  { slug: "fisheries-and-oceans-canada", priority: 2, display_name: "Fisheries", official_name: "Fisheries and Oceans Canada" },
  { slug: "global-affairs-canada", priority: 2, display_name: "Global Affairs Canada", official_name: "Global Affairs Canada" },
  { slug: "health-canada", priority: 1, display_name: "Health", official_name: "Health Canada" },
  { slug: "immigration-refugees-and-citizenship-canada", priority: 1, display_name: "Immigration", official_name: "Immigration, Refugees and Citizenship Canada" },
  { slug: "indigenous-services-canada", priority: 2, display_name: "Indigenous Services", official_name: "Indigenous Services Canada" },
  { slug: "infrastructure-canada", priority: 1, display_name: "Housing & Infrastructure", official_name: "Infrastructure Canada" },
  { slug: "innovation-science-and-economic-development-canada", priority: 1, display_name: "Industry", official_name: "Innovation, Science and Economic Development Canada" },
  { slug: "justice-canada", priority: 2, display_name: "Justice", official_name: "Justice Canada" },
  { slug: "national-defence", priority: 1, display_name: "Defence", official_name: "National Defence" },
  { slug: "natural-resources-canada", priority: 1, display_name: "Energy & Natural Resources", official_name: "Natural Resources Canada" },
  { slug: "prime-minister-office", priority: 1, display_name: "Prime Minister", official_name: "Prime Minister's Office" },
  { slug: "privy-council-office", priority: 2, display_name: "Privy Council", official_name: "Privy Council Office" },
  { slug: "intergovernmental-affairs", priority: 2, display_name: "Intergovernmental Affairs", official_name: "Intergovernmental Affairs" },
  { slug: "public-safety-canada", priority: 2, display_name: "Public Safety", official_name: "Public Safety Canada" },
  { slug: "public-services-and-procurement-canada", priority: 1, display_name: "Government Transformation", official_name: "Public Services and Procurement Canada" },
  { slug: "rural-economic-development", priority: 2, display_name: "Rural Development", official_name: "Rural Economic Development" },
  { slug: "transport-canada", priority: 1, display_name: "Transport & Internal Trade", official_name: "Transport Canada" },
  { slug: "treasury-board-of-canada-secretariat", priority: 2, display_name: "Treasury Board", official_name: "Treasury Board of Canada Secretariat" },
  { slug: "veterans-affairs-canada", priority: 2, display_name: "Veterans Affairs", official_name: "Veterans Affairs Canada" },
  { slug: "women-and-gender-equality-canada", priority: 2, display_name: "Gender Equality", official_name: "Women and Gender Equality Canada" }
]

departments_data.each do |attrs|
  Department.find_or_create_by!(slug: attrs[:slug], government: government) do |dept|
    dept.official_name = attrs[:official_name]
    dept.display_name = attrs[:display_name]
    dept.priority = attrs[:priority]
  end
end

# Ministers are now synced live from ourcommons.ca via MinistersSyncJob.
# Run `MinistersSyncJob.perform_now` to populate ministers.

puts "Seeding Feeds..."

feed_data = [
  {
    title: "Canada Gazette Part I: Official Regulations",
    url: "https://gazette.gc.ca/rss/p1-eng.xml"
  },
  {
    title: "Canada Gazette Part II: Official Regulations",
    url: "https://gazette.gc.ca/rss/p2-eng.xml"
  },
  {
    title: "Canada Gazette Part III: Acts of Parliament",
    url: "https://gazette.gc.ca/rss/en-ls-eng.xml"
  },
  {
    title: "Canada News Backgrounders",
    url: "https://api.io.canada.ca/io-server/gc/news/en/v2?type=backgrounders&sort=publishedDate&orderBy=desc&pick=100&format=atom&atomtitle=backgrounders"
  },
  {
    title: "Canada News Speeches",
    url: "https://api.io.canada.ca/io-server/gc/news/en/v2?type=speeches&sort=publishedDate&orderBy=desc&pick=100&format=atom&atomtitle=speeches"
  },
  {
    title: "Canada News Statements",
    url: "https://api.io.canada.ca/io-server/gc/news/en/v2?type=statements&sort=publishedDate&orderBy=desc&pick=100&format=atom&atomtitle=statements"
  },
  {
    title: "Department of Finance News Statements",
    url: "https://api.io.canada.ca/io-server/gc/news/en/v2?dept=departmentfinance&type=newsreleases&sort=publishedDate&orderBy=desc&pick=100&format=atom&atomtitle=Canada%20News%20Centre%20-%20Department%20of%20Finance%20Canada%20-%20News%20Releases"
  },
  # Priority 1 data sources (Plan 7)
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
  # Priority 2 data sources (Plan 7)
  {
    title: "Parliamentary Budget Officer Reports",
    url: "https://www.pbo-dpb.ca/en/feed.xml"
  }
]

feed_data.each do |attrs|
  feed = Feed.find_or_create_by(
    **attrs,
    government: government
  )
end

puts "Seeding Promises..."

require_relative 'canada_promises_2024'

puts "Matching Promises to Departments..."

require_relative 'department_promises'

puts "Seeding Canadian Builders..."

builders_data = [
  {
    id: 1,
    name: "Ryan Reynolds",
    title: "Actor & Entrepreneur",
    location: "Vancouver, BC",
    category: "Entertainment",
    description:
      "From Vancouver comedy clubs to Hollywood A-lister, Ryan built a media empire spanning film, spirits, and sports. His authentic voice and business acumen turned him into one of the most influential Canadian exports.",
    achievement: "Built multiple 9-figure businesses while maintaining authentic Canadian humor",
    avatar: "/placeholder.svg?height=120&width=120"
  },
  {
    id: 2,
    name: "Tobias Lütke",
    title: "Founder & CEO, Shopify",
    location: "Ottawa, ON",
    category: "Technology",
    description:
      "A German immigrant who couldn't find good e-commerce software, so he built Shopify. Today, his platform powers over 4 million businesses worldwide and has created countless entrepreneurial success stories.",
    achievement: "Democratized e-commerce for millions of entrepreneurs globally",
    avatar: "/placeholder.svg?height=120&width=120"
  },
  {
    id: 3,
    name: "Margaret Atwood",
    title: "Author & Visionary",
    location: "Toronto, ON",
    category: "Literature",
    description:
      "Her dystopian masterpiece 'The Handmaid's Tale' predicted societal challenges decades before they emerged. Margaret's work continues to shape global conversations about freedom, power, and human rights.",
    achievement: "Authored works that became cultural phenomena and social movements",
    avatar: "/placeholder.svg?height=120&width=120"
  },
  {
    id: 4,
    name: "Chris Hadfield",
    title: "Astronaut & Inspiration Leader",
    location: "Milton, ON",
    category: "Science",
    description:
      "From small-town Ontario to commanding the International Space Station, Chris showed the world that Canadians can reach for the stars. His space videos inspired millions to pursue STEM careers.",
    achievement: "First Canadian to command the International Space Station",
    avatar: "/placeholder.svg?height=120&width=120"
  },
  {
    id: 5,
    name: "Céline Dion",
    title: "Global Music Icon",
    location: "Charlemagne, QC",
    category: "Music",
    description:
      "From singing in her family's piano bar to selling 250+ million records worldwide, Céline proved that talent, determination, and authenticity can conquer any stage. Her voice became Canada's gift to the world.",
    achievement: "One of the best-selling music artists of all time with 250M+ records sold",
    avatar: "/placeholder.svg?height=120&width=120"
  },
  {
    id: 6,
    name: "David Suzuki",
    title: "Environmental Pioneer",
    location: "Vancouver, BC",
    category: "Environment",
    description:
      "For over 50 years, David has been Canada's environmental conscience. His work educated generations about climate change and inspired a global movement toward sustainable living.",
    achievement: "Educated millions about environmental science through 'The Nature of Things'",
    avatar: "/placeholder.svg?height=120&width=120"
  }
]

builders_data.each do |attrs|
  CanadianBuilder.find_or_create_by!(name: attrs[:name], government: government) do |builder|
    builder.title = attrs[:title]
    builder.location = attrs[:location]
    builder.category = attrs[:category]
    builder.description = attrs[:description]
    builder.achievement = attrs[:achievement]
    builder.avatar = attrs[:avatar]
    builder.website = attrs[:website]
    builder.slug = attrs[:name].parameterize
  end
end

puts "Seeding Evidences..."

require_relative 'statcan_datasets'

require_relative 'bills'

puts "Done seeding"
