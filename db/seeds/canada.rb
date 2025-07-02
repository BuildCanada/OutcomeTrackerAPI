government = Government.find_or_create_by!(name: "Government of Canada") do |g|
  g.slug = "federal"
end


departments_data = [
  { slug: "agriculture-and-agri-food-canada", priority: 2, display_name: "Agriculture", official_name: "Agriculture and Agri-Food Canada" },
  { slug: "artificial-intelligence-and-digital-innovation", priority: 1, display_name: "Digital Innovation", official_name: "Artificial Intelligence and Digital Innovation" },
  { slug: "atlantic-canada-opportunities-agency", priority: 2, display_name: "ACOA", official_name: "Atlantic Canada Opportunities Agency" },
  { slug: "canada-economic-development-for-quebec-regions", priority: 2, display_name: "CED Quebec", official_name: "Canada Economic Development for Quebec Regions" },
  { slug: "canada-revenue-agency", priority: 2, display_name: "Revenue", official_name: "Canada Revenue Agency" },
  { slug: "canadian-heritage", priority: 2, display_name: "Heritage", official_name: "Canadian Heritage" },
  { slug: "crown-indigenous-relations-and-northern-affairs-canada", priority: 2, display_name: "Crown-Indigenous Relations", official_name: "Crown-Indigenous Relations and Northern Affairs Canada" },
  { slug: "emergency-preparedness-canada", priority: 2, display_name: "Emergency Preparedness", official_name: "Emergency Preparedness Canada" },
  { slug: "employment-and-social-development-canada", priority: 2, display_name: "Employment", official_name: "Employment and Social Development Canada" },
  { slug: "environment-and-climate-change-canada", priority: 2, display_name: "Environment", official_name: "Environment and Climate Change Canada" },
  { slug: "federal-economic-development-agency-for-southern-ontario", priority: 2, display_name: "FedDev Ontario", official_name: "Federal Economic Development Agency for Southern Ontario" },
  { slug: "finance-canada", priority: 1, display_name: "Finance", official_name: "Finance Canada" },
  { slug: "fisheries-and-oceans-canada", priority: 2, display_name: "Fisheries", official_name: "Fisheries and Oceans Canada" },
  { slug: "global-affairs-canada", priority: 2, display_name: "Foreign Affairs", official_name: "Global Affairs Canada" },
  { slug: "health-canada", priority: 1, display_name: "Health", official_name: "Health Canada" },
  { slug: "immigration-refugees-and-citizenship-canada", priority: 1, display_name: "Immigration", official_name: "Immigration, Refugees and Citizenship Canada" },
  { slug: "indigenous-services-canada", priority: 2, display_name: "Indigenous Services", official_name: "Indigenous Services Canada" },
  { slug: "infrastructure-canada", priority: 1, display_name: "Housing", official_name: "Infrastructure Canada" },
  { slug: "innovation-science-and-economic-development-canada", priority: 1, display_name: "Industry", official_name: "Innovation, Science and Economic Development Canada" },
  { slug: "justice-canada", priority: 2, display_name: "Justice", official_name: "Justice Canada" },
  { slug: "multiple-departments-needs-review", priority: 2, display_name: "Multiple", official_name: "Multiple Departments - Needs Review" },
  { slug: "national-defence", priority: 1, display_name: "Defence", official_name: "National Defence" },
  { slug: "natural-resources-canada", priority: 1, display_name: "Energy", official_name: "Natural Resources Canada" },
  { slug: "prime-minister-office", priority: 1, display_name: "Prime Minister", official_name: "Prime Minister's Office" },
  { slug: "privy-council-office", priority: 2, display_name: "Privy Council", official_name: "Privy Council Office" },
  { slug: "privy-council-office-intergovernmental-affairs-secretariat", priority: 2, display_name: "Privy Council / IGA", official_name: "Privy Council Office / Intergovernmental Affairs Secretariat" },
  { slug: "public-safety-canada", priority: 2, display_name: "Public Safety", official_name: "Public Safety Canada" },
  { slug: "public-services-and-procurement-canada", priority: 1, display_name: "Government Transformation", official_name: "Public Services and Procurement Canada" },
  { slug: "rural-economic-development", priority: 2, display_name: "Rural Development", official_name: "Rural Economic Development" },
  { slug: "transport-canada", priority: 1, display_name: "Internal Trade", official_name: "Transport Canada" },
  { slug: "treasury-board-of-canada-secretariat", priority: 2, display_name: "Treasury", official_name: "Treasury Board of Canada Secretariat" },
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

# Ministers data
ministers_data = [
  {
    order_of_precedence: 1,
    person_short_honorific: "Right Hon.",
    first_name: "Mark",
    last_name: "Carney",
    title: "Prime Minister",
    started_at: "2025-03-14T11:31:00",
    ended_at: nil,
    department_slug: "prime-minister-office",
    avatar_url: "https://www.ourcommons.ca/Content/Parliamentarians/Images/OfficialMPPhotos/45/CarneyMark_Lib.jpg",
    role: "Prime Minister"
  },
  {
    order_of_precedence: 2,
    person_short_honorific: "Hon.",
    first_name: "Shafqat",
    last_name: "Ali",
    title: "President of the Treasury Board",
    started_at: "2025-05-13T10:45:00",
    ended_at: nil,
    department_slug: "treasury-board-of-canada-secretariat",
    avatar_url: "https://www.ourcommons.ca/Content/Parliamentarians/Images/OfficialMPPhotos/44/AliShafqat_Lib.jpg",
    role: "Minister"
  },
  {
    order_of_precedence: 3,
    person_short_honorific: "Hon.",
    first_name: "Rebecca",
    last_name: "Alty",
    title: "Minister of Crown-Indigenous Relations",
    started_at: "2025-05-13T10:45:00",
    ended_at: nil,
    department_slug: "crown-indigenous-relations-and-northern-affairs-canada",
    avatar_url: "https://www.ourcommons.ca/Content/Parliamentarians/Images/OfficialMPPhotos/45/AltyRebecca_Lib.jpg"
  },
  {
    order_of_precedence: 4,
    person_short_honorific: "Hon.",
    first_name: "Anita",
    last_name: "Anand",
    title: "Minister of Foreign Affairs",
    started_at: "2025-05-13T10:45:00",
    ended_at: nil,
    department_slug: "global-affairs-canada",
    avatar_url: "https://www.ourcommons.ca/Content/Parliamentarians/Images/OfficialMPPhotos/45/AnandAnita_Lib.jpg"
  },
  {
    order_of_precedence: 5,
    person_short_honorific: "Hon.",
    first_name: "Gary",
    last_name: "Anandasangaree",
    title: "Minister of Public Safety",
    started_at: "2025-05-13T10:45:00",
    ended_at: nil,
    department_slug: "public-safety-canada",
    avatar_url: "https://www.ourcommons.ca/Content/Parliamentarians/Images/OfficialMPPhotos/45/AnandasangareeGary_Lib.jpg"
  },
  {
    order_of_precedence: 6,
    person_short_honorific: "Hon.",
    first_name: "François-Philippe",
    last_name: "Champagne",
    title: "Minister of Finance and National Revenue",
    started_at: "2025-05-13T10:45:00",
    ended_at: nil,
    department_slug: "finance-canada",
    avatar_url: "https://www.ourcommons.ca/Content/Parliamentarians/Images/OfficialMPPhotos/45/ChampagneFrancoisPhilippe_Lib.jpg"
  },
  {
    order_of_precedence: 6,
    person_short_honorific: "Hon.",
    first_name: "François-Philippe",
    last_name: "Champagne",
    title: "Minister of Finance and National Revenue",
    started_at: "2025-05-13T10:45:00",
    ended_at: nil,
    department_slug: "canada-revenue-agency",
    avatar_url: "https://www.ourcommons.ca/Content/Parliamentarians/Images/OfficialMPPhotos/45/ChampagneFrancoisPhilippe_Lib.jpg"
  },
  {
    order_of_precedence: 7,
    person_short_honorific: "Hon.",
    first_name: "Rebecca",
    last_name: "Chartrand",
    title: "Minister of Northern and Arctic Affairs",
    started_at: "2025-05-13T10:45:00",
    ended_at: nil,
    department_slug: "crown-indigenous-relations-and-northern-affairs-canada",
    avatar_url: "https://www.ourcommons.ca/Content/Parliamentarians/Images/OfficialMPPhotos/45/ChartrandRebecca_Lib.jpg"
  },
  {
    order_of_precedence: 8,
    person_short_honorific: "Hon.",
    first_name: "Julie",
    last_name: "Dabrusin",
    title: "Minister of Environment and Climate Change",
    started_at: "2025-05-13T10:45:00",
    ended_at: nil,
    department_slug: "environment-and-climate-change-canada",
    avatar_url: "https://www.ourcommons.ca/Content/Parliamentarians/Images/OfficialMPPhotos/44/DabrusinJulie_Lib.jpg"
  },
  {
    order_of_precedence: 9,
    person_short_honorific: "Hon.",
    first_name: "Sean",
    last_name: "Fraser",
    title: "Minister of Justice",
    started_at: "2025-05-13T10:45:00",
    ended_at: nil,
    department_slug: "justice-canada",
    avatar_url: "https://www.ourcommons.ca/Content/Parliamentarians/Images/OfficialMPPhotos/44/FraserSean_Lib.jpg"
  },
  {
    order_of_precedence: 10,
    person_short_honorific: "Hon.",
    first_name: "Chrystia",
    last_name: "Freeland",
    title: "Minister of Transport and Internal Trade",
    started_at: "2025-05-13T10:45:00",
    ended_at: nil,
    department_slug: "transport-canada",
    avatar_url: "https://www.ourcommons.ca/Content/Parliamentarians/Images/OfficialMPPhotos/44/FreelandChrystia_Lib.jpg"
  },
  {
    order_of_precedence: 11,
    person_short_honorific: "Hon.",
    first_name: "Steven",
    last_name: "Guilbeault",
    title: "Minister of Canadian Identity and Culture",
    started_at: "2025-05-13T10:45:00",
    ended_at: nil,
    department_slug: "canadian-heritage",
    avatar_url: "https://www.ourcommons.ca/Content/Parliamentarians/Images/OfficialMPPhotos/44/GuilbeaultSteven_Lib.jpg"
  },
  {
    order_of_precedence: 12,
    person_short_honorific: "Hon.",
    first_name: "Mandy",
    last_name: "Gull-Masty",
    title: "Minister of Indigenous Services",
    started_at: "2025-05-13T10:45:00",
    ended_at: nil,
    department_slug: "indigenous-services-canada",
    avatar_url: "https://www.ourcommons.ca/Content/Parliamentarians/Images/OfficialMPPhotos/45/Gull-MastyMandy_Lib.jpg"
  },
  {
    order_of_precedence: 13,
    person_short_honorific: "Hon.",
    first_name: "Patty",
    last_name: "Hajdu",
    title: "Minister of Jobs and Families",
    started_at: "2025-05-13T10:45:00",
    ended_at: nil,
    department_slug: "employment-and-social-development-canada",
    avatar_url: "https://www.ourcommons.ca/Content/Parliamentarians/Images/OfficialMPPhotos/44/HajduPatty_Lib.jpg"
  },
  {
    order_of_precedence: 14,
    person_short_honorific: "Hon.",
    first_name: "Tim",
    last_name: "Hodgson",
    title: "Minister of Energy and Natural Resources",
    started_at: "2025-05-13T10:45:00",
    ended_at: nil,
    department_slug: "natural-resources-canada",
    avatar_url: "https://www.ourcommons.ca/Content/Parliamentarians/Images/OfficialMPPhotos/45/HodgsonTimothyEdward_Lib.jpg"
  },
  {
    order_of_precedence: 16,
    person_short_honorific: "Hon.",
    first_name: "Dominic",
    last_name: "LeBlanc",
    title: "President of the King's Privy Council for Canada",
    started_at: "2025-05-13T10:45:00",
    ended_at: nil,
    department_slug: "privy-council-office",
    avatar_url: "https://www.ourcommons.ca/Content/Parliamentarians/Images/OfficialMPPhotos/44/LeBlancDominic_Lib.jpg"
  },
  {
    order_of_precedence: 17,
    person_short_honorific: "Hon.",
    first_name: "Joël",
    last_name: "Lightbound",
    title: "Minister of Government Transformation, Public Works and Procurement",
    started_at: "2025-05-13T10:45:00",
    ended_at: nil,
    department_slug: "public-services-and-procurement-canada",
    avatar_url: "https://www.ourcommons.ca/Content/Parliamentarians/Images/OfficialMPPhotos/44/LightboundJo%C3%ABl_Lib.jpg"
  },
  {
    order_of_precedence: 18,
    person_short_honorific: "Hon.",
    first_name: "Heath",
    last_name: "MacDonald",
    title: "Minister of Agriculture and Agri-Food",
    started_at: "2025-05-13T10:45:00",
    ended_at: nil,
    department_slug: "agriculture-and-agri-food-canada",
    avatar_url: "https://www.ourcommons.ca/Content/Parliamentarians/Images/OfficialMPPhotos/44/MacDonaldHeath_CPC.jpg"
  },
  {
    order_of_precedence: 19,
    person_short_honorific: "Hon.",
    first_name: "Steven",
    last_name: "MacKinnon",
    title: "Leader of the Government in the House of Commons",
    started_at: "2025-05-13T10:45:00",
    ended_at: nil,
    department_slug: "privy-council-office",
    avatar_url: "https://www.ourcommons.ca/Content/Parliamentarians/Images/OfficialMPPhotos/44/MacKinnonSteven_Lib.jpg"
  },
  {
    order_of_precedence: 20,
    person_short_honorific: "Hon.",
    first_name: "David",
    last_name: "McGuinty",
    title: "Minister of National Defence",
    started_at: "2025-05-13T10:45:00",
    ended_at: nil,
    department_slug: "national-defence",
    avatar_url: "https://www.ourcommons.ca/Content/Parliamentarians/Images/OfficialMPPhotos/44/McGuintyDavidJ._Lib.jpg"
  },
  {
    order_of_precedence: 21,
    person_short_honorific: "Hon.",
    first_name: "Jill",
    last_name: "McKnight",
    title: "Minister of Veterans Affairs",
    started_at: "2025-05-13T10:45:00",
    ended_at: nil,
    department_slug: "veterans-affairs-canada",
    avatar_url: "https://www.ourcommons.ca/Content/Parliamentarians/Images/OfficialMPPhotos/45/McKnightJill_Lib.jpg"
  },
  {
    order_of_precedence: 22,
    person_short_honorific: "Hon.",
    first_name: "Lena Metlege",
    last_name: "Diab",
    title: "Minister of Immigration, Refugees and Citizenship",
    started_at: "2025-05-13T10:45:00",
    ended_at: nil,
    department_slug: "immigration-refugees-and-citizenship-canada",
    avatar_url: "https://www.ourcommons.ca/Content/Parliamentarians/Images/OfficialMPPhotos/45/MetlegeDiabLena_Lib.jpg"
  },
  {
    order_of_precedence: 23,
    person_short_honorific: "Hon.",
    first_name: "Marjorie",
    last_name: "Michel",
    title: "Minister of Health",
    started_at: "2025-05-13T10:45:00",
    ended_at: nil,
    department_slug: "health-canada",
    avatar_url: "https://www.ourcommons.ca/Content/Parliamentarians/Images/OfficialMPPhotos/45/MichelMarjorie_Lib.jpg"
  },
  {
    order_of_precedence: 24,
    person_short_honorific: "Hon.",
    first_name: "Eleanor",
    last_name: "Olszewski",
    title: "Minister of Emergency Management and Community Resilience",
    started_at: "2025-05-13T10:45:00",
    ended_at: nil,
    department_slug: "emergency-preparedness-canada",
    avatar_url: "https://www.ourcommons.ca/Content/Parliamentarians/Images/OfficialMPPhotos/45/OlszewskiEleanor_Lib.jpg"
  },
  {
    order_of_precedence: 25,
    person_short_honorific: "Hon.",
    first_name: "Gregor",
    last_name: "Robertson",
    title: "Minister of Housing and Infrastructure",
    started_at: "2025-05-13T10:45:00",
    ended_at: nil,
    department_slug: "infrastructure-canada",
    avatar_url: "https://www.ourcommons.ca/Content/Parliamentarians/Images/OfficialMPPhotos/45/RobertsonGregor_Lib.jpg"
  },
  {
    order_of_precedence: 26,
    person_short_honorific: "Hon.",
    first_name: "Maninder",
    last_name: "Sidhu",
    title: "Minister of International Trade",
    started_at: "2025-05-13T10:45:00",
    ended_at: nil,
    department_slug: "global-affairs-canada",
    avatar_url: "https://www.ourcommons.ca/Content/Parliamentarians/Images/OfficialMPPhotos/44/SidhuManinder_Lib.jpg"
  },
  {
    order_of_precedence: 27,
    person_short_honorific: "Hon.",
    first_name: "Evan",
    last_name: "Solomon",
    title: "Minister of Artificial Intelligence and Digital Innovation",
    started_at: "2025-05-13T10:45:00",
    ended_at: nil,
    department_slug: "artificial-intelligence-and-digital-innovation",
    avatar_url: "https://www.ourcommons.ca/Content/Parliamentarians/Images/OfficialMPPhotos/45/SolomonEvan_Lib.jpg"
  },
  {
    order_of_precedence: 28,
    person_short_honorific: "Hon.",
    first_name: "Joanne",
    last_name: "Thompson",
    title: "Minister of Fisheries",
    started_at: "2025-05-13T10:45:00",
    ended_at: nil,
    department_slug: "fisheries-and-oceans-canada",
    avatar_url: "https://www.ourcommons.ca/Content/Parliamentarians/Images/OfficialMPPhotos/44/ThompsonJoanne_Lib.jpg"
  },
  {
    order_of_precedence: 29,
    person_short_honorific: "Hon.",
    first_name: "Rechie",
    last_name: "Valdez",
    title: "Minister of Women and Gender Equality",
    started_at: "2025-05-13T10:45:00",
    ended_at: nil,
    department_slug: "women-and-gender-equality-canada",
    avatar_url: "https://www.ourcommons.ca/Content/Parliamentarians/Images/OfficialMPPhotos/45/ValdezRechie_Lib.jpg"
  },
  {
    order_of_precedence: 30,
    person_short_honorific: "Hon.",
    first_name: "Buckley",
    last_name: "Belanger",
    title: "Secretary of State (Rural Development)",
    started_at: "2025-05-13T10:45:00",
    ended_at: nil,
    department_slug: "rural-economic-development",
    avatar_url: "https://www.ourcommons.ca/Content/Parliamentarians/Images/OfficialMPPhotos/45/BelangerBuckley_Lib.jpg"
  },
  {
    order_of_precedence: 31,
    person_short_honorific: "Hon.",
    first_name: "Stephen",
    last_name: "Fuhr",
    title: "Secretary of State (Defence Procurement)",
    started_at: "2025-05-13T10:45:00",
    ended_at: nil,
    department_slug: "national-defence",
    avatar_url: "https://www.ourcommons.ca/Content/Parliamentarians/Images/OfficialMPPhotos/45/FuhrStephen_Lib.jpg"
  },
  {
    order_of_precedence: 32,
    person_short_honorific: "Hon.",
    first_name: "Anna",
    last_name: "Gainey",
    title: "Secretary of State (Children and Youth)",
    started_at: "2025-05-13T10:45:00",
    ended_at: nil,
    department_slug: "employment-and-social-development-canada",
    avatar_url: "https://www.ourcommons.ca/Content/Parliamentarians/Images/OfficialMPPhotos/44/GaineyAnna_Lib.jpg"
  },
  {
    order_of_precedence: 33,
    person_short_honorific: "Hon.",
    first_name: "Wayne",
    last_name: "Long",
    title: "Secretary of State (Canada Revenue Agency and Financial Institutions)",
    started_at: "2025-05-13T10:45:00",
    ended_at: nil,
    department_slug: "canada-revenue-agency",
    avatar_url: "https://www.ourcommons.ca/Content/Parliamentarians/Images/OfficialMPPhotos/44/LongWayne_Lib.jpg"
  },
  {
    order_of_precedence: 34,
    person_short_honorific: "Hon.",
    first_name: "Stephanie",
    last_name: "McLean",
    title: "Secretary of State (Seniors)",
    started_at: "2025-05-13T10:45:00",
    ended_at: nil,
    department_slug: "employment-and-social-development-canada",
    avatar_url: "https://www.ourcommons.ca/Content/Parliamentarians/Images/OfficialMPPhotos/45/McLeanStephanie_Lib.jpg"
  },
  {
    order_of_precedence: 35,
    person_short_honorific: "Hon.",
    first_name: "Nathalie",
    last_name: "Provost",
    title: "Secretary of State (Nature)",
    started_at: "2025-05-13T10:45:00",
    ended_at: nil,
    department_slug: "environment-and-climate-change-canada",
    avatar_url: "https://www.ourcommons.ca/Content/Parliamentarians/Images/OfficialMPPhotos/45/ProvostNathalie_Lib.jpg"
  },
  {
    order_of_precedence: 36,
    person_short_honorific: "Hon.",
    first_name: "Ruby",
    last_name: "Sahota",
    title: "Secretary of State (Combatting Crime)",
    started_at: "2025-05-13T10:45:00",
    ended_at: nil,
    department_slug: "public-safety-canada",
    avatar_url: "https://www.ourcommons.ca/Content/Parliamentarians/Images/OfficialMPPhotos/44/SahotaRuby_Lib.jpg"
  },
  {
    order_of_precedence: 37,
    person_short_honorific: "Hon.",
    first_name: "Randeep",
    last_name: "Sarai",
    title: "Secretary of State (International Development)",
    started_at: "2025-05-13T10:45:00",
    ended_at: nil,
    department_slug: "global-affairs-canada",
    avatar_url: "https://www.ourcommons.ca/Content/Parliamentarians/Images/OfficialMPPhotos/44/SaraiRandeep_Lib.jpg"
  },
  {
    order_of_precedence: 38,
    person_short_honorific: "Hon.",
    first_name: "Adam",
    last_name: "van Koeverden",
    title: "Secretary of State (Sport)",
    started_at: "2025-05-13T10:45:00",
    ended_at: nil,
    department_slug: "canadian-heritage",
    avatar_url: "https://www.ourcommons.ca/Content/Parliamentarians/Images/OfficialMPPhotos/44/vanKoeverdenAdam_Lib.jpg"
  },
  {
    order_of_precedence: 39,
    person_short_honorific: "Hon.",
    first_name: "John",
    last_name: "Zerucelli",
    title: "Secretary of State (Labour)",
    started_at: "2025-05-13T10:45:00",
    ended_at: nil,
    department_slug: "employment-and-social-development-canada",
    avatar_url: "https://www.ourcommons.ca/Content/Parliamentarians/Images/OfficialMPPhotos/45/ZerucelliJohn_Lib.jpg"
  }
]

ministers_data.each do |attrs|
  department = Department.find_by!(slug: attrs[:department_slug], government: government)
  role = attrs[:role] || attrs[:title].include?("Secretary of State") ? "Secretary of State" : "Minister"

  Minister.find_or_create_by!(
    department: department,
    government: government,
    started_at: attrs[:started_at],
    role: role
  ) do |minister|
    minister.person_short_honorific = attrs[:person_short_honorific]
    minister.order_of_precedence = attrs[:order_of_precedence]
    minister.first_name = attrs[:first_name]
    minister.last_name = attrs[:last_name]
    minister.title = attrs[:title]
    minister.started_at = attrs[:started_at]
    minister.ended_at = attrs[:ended_at]
    minister.avatar_url = attrs[:avatar_url]
  end
end

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

puts "Seeding Evidences..."

puts "Done seeding"
