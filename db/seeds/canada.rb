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
  }
]

feed_data.each do |attrs|
  feed = Feed.find_or_create_by(
    **attrs,
    government: government
  )
end

puts "Seeding Promises..."

promise_data = {
  promise_id: "LPC_20250419_OTHER_71c8234b",
  action_type_classified_at: "2024-04-20T22:23:06Z",
  action_type_confidence: 3,
  action_type_rationale: "The promise outlines a series of strategic actions...",
  background_and_context: "In the context of evolving digital infrastructure...",
  bc_priority_score: 7,
  bc_promise_direction: "forward",
  bc_promise_rank: "high",
  bc_promise_rank_rationale: "Addresses urgent gaps in policy...",
  bc_ranked_at: "2024-04-21T10:12:00Z",
  candidate_or_government: "LPC",
  category: "Infrastructure",
  concise_title: "Expand digital access",
  date_issued: "2024-04-19",
  description: "We promise to expand digital access across rural Canada...",
  evidence_count: 5,
  explanation_enrichment_model: "gpt-4",
  explanation_enrichment_status: "complete",
  explanation_enriched_at: "2024-04-21T12:00:00Z",
  history_generated_at: "2024-04-21T14:30:00Z",
  implied_action_type: "legislation",
  ingested_at: "2024-04-19T09:00:00Z",
  keywords_context_used: "rural access, connectivity",
  keywords_enrichment_status: "complete",
  keywords_enriched_at: "2024-04-21T11:45:00Z",
  keywords_extracted_at: "2024-04-21T11:30:00Z",
  last_enrichment_at: "2024-04-21T14:30:00Z",
  last_evidence_date: "2024-04-20",
  last_progress_update_at: "2024-04-22T10:00:00Z",
  last_scored_at: "2024-04-22T10:05:00Z",
  last_updated_at: "2024-04-22T10:10:00Z",
  linking_preprocessing_done_at: "2024-04-21T15:00:00Z",
  linking_processed_at: "2024-04-21T15:30:00Z",
  linking_status: "linked",
  migration_status_ed_at: "2024-04-21T16:00:00Z",
  migration_version: "v2",
  parliament_session_id: "44-1",
  party: "Liberal",
  party_code: "LPC",
  progress_score: 4,
  progress_score_1_to_5: 4,
  progress_scoring_model: "v1.3",
  progress_status: "in progress",
  progress_summary: "Significant infrastructure projects have been launched.",
  rationale_format_fixed_at: "2024-04-21T16:30:00Z",
  region_code: "CA-ON",
  responsible_department_lead: "Innovation, Science and Economic Development Canada",
  scoring_method: "automated",
  scoring_model: "gpt-4-vision",
  source_document_url: "https://example.com/promise-doc",
  source_type: "platform",
  status: "active",
  text: "We promise to expand digital access...",
  extracted_keywords_concepts: [ "digital access", "rural", "infrastructure" ],
  intended_impact_and_objectives: [ "Bridge the digital divide", "Support rural communities" ],
  what_it_means_for_canadians: [ "Improved internet access", "Greater economic opportunity" ],
  linked_evidence_ids: [ "EVID1234", "EVID5678" ],
  relevant_departments: [ "ISED", "Heritage Canada" ],
  commitment_history_rationale: { "2024-04" => "Budget allocated" },
  commitment_history_timeline: { "2024-04" => "Bill introduced" },
  key_points: { "summary" => "High priority infrastructure expansion" },
  policy_areas: { "digital" => true, "rural" => true },
  target_groups: { "rural_residents" => true }
}

Promise.find_or_initialize_by(promise_id: promise_data[:promise_id]).tap do |p|
  p.assign_attributes(promise_data)
  p.save!
end

puts "Seeding Evidences..."

evidence_data = {
  raw_gazette_notice_id: "GN-2024-001",
  rias_summary: "This notice outlines planned policy updates...",
  description_or_details: "Full text of the Gazette outlining broadband expansion...",
  evidence_date: "2024-04-20T09:00:00Z",
  evidence_id: "EVID1234",
  evidence_source_type: "gazette",
  hybrid_linking_avg_confidence: 0.87,
  hybrid_linking_method: "AI + manual",
  hybrid_linking_timestamp: "2024-04-21T10:00:00Z",
  ingested_at: "2024-04-20T12:00:00Z",
  parliament_session_id: "44-1",
  promise_linking_processed_at: "2024-04-21T12:30:00Z",
  promise_linking_status: "linked",
  promise_links_found2: 1,
  source_document_raw_id: "DOC-2024-XYZ",
  source_url: "https://example.com/evidence-doc",
  title_or_summary: "Government expands rural broadband",
  key_concepts: [ "broadband", "rural", "infrastructure" ],
  linked_departments: [ "ISED" ],
  promise_ids: [ "LPC_20250419_OTHER_71c8234b" ],
  llm_analysis_raw: {
    "summary" => "The document supports the stated promise to expand rural digital access.",
    "confidence" => 0.92
  }
}

Evidence.find_or_initialize_by(evidence_id: evidence_data[:evidence_id]).tap do |e|
  e.assign_attributes(evidence_data)
  e.save!
end

puts "Done seeding"
