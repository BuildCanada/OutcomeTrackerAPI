policy_areas = [
  { name: "Defence and Security", slug: "defence", description: "Military spending, defence procurement, and security initiatives" },
  { name: "Healthcare", slug: "healthcare", description: "Health services, medical transfers, and healthcare funding" },
  { name: "Environment and Climate", slug: "environment", description: "Environmental protection and climate action initiatives" },
  { name: "Economy and Trade", slug: "economy", description: "Economic development and international trade" },
  { name: "Indigenous Affairs", slug: "indigenous", description: "Indigenous relations and reconciliation" },
  { name: "Social Programs", slug: "social", description: "Employment, housing, childcare, and social services" },
  { name: "Justice and Public Safety", slug: "justice", description: "Criminal justice, public safety, and law enforcement" },
  { name: "Education and Research", slug: "education", description: "Post-secondary education and research funding" },
  { name: "Infrastructure and Transport", slug: "infrastructure", description: "Transportation, broadband, and physical infrastructure" },
  { name: "Veterans", slug: "veterans", description: "Veterans benefits and military personnel support" },
  { name: "Immigration", slug: "immigration", description: "Immigration policy, refugees, and citizenship" },
  { name: "Foreign Affairs", slug: "foreign-affairs", description: "Diplomacy, international development, and foreign policy" },
  { name: "Agriculture and Food", slug: "agriculture", description: "Agriculture, food security, and rural development" },
  { name: "Housing", slug: "housing", description: "Housing affordability and construction" },
  { name: "Democratic Reform", slug: "democratic-reform", description: "Electoral reform, transparency, and governance" },
  { name: "Government Reform", slug: "government-reform", description: "Public service modernization, regulatory reform, and government efficiency" }
]

policy_areas.each do |attrs|
  PolicyArea.find_or_create_by!(slug: attrs[:slug]) do |pa|
    pa.name = attrs[:name]
    pa.description = attrs[:description]
  end
end

puts "Seeded #{PolicyArea.count} policy areas"
