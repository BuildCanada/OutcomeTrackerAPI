puts "Seeding DepartmentPromises..."

MAPPING = {
  "Minister of National Defence": "national-defence",
  "Minister of Public Safety": "public-safety-canada",
  "Secretary of State (Defence Procurement)": "national-defence",
  "Minister of Industry": "innovation-science-and-economic-development-canada",
  "Minister of Foreign Affairs": "global-affairs-canada",
  "Minister of Finance": "finance-canada",
  "Minister of Jobs and Families": "employment-and-social-development-canada",
  "Secretary of State (Children and Youth)": "employment-and-social-development-canada",
  "Minister of Indigenous Services": "indigenous-services-canada",
  "Minister of Immigration, Refugees and Citizenship": "immigration-refugees-and-citizenship-canada",
  "Minister of Environment and Climate Change": "environment-and-climate-change-canada",
  "President of the Treasury Board": "treasury-board-of-canada-secretariat",
  "Minister of Crown-Indigenous Relations": "crown-indigenous-relations-and-northern-affairs-canada",
  "Minister of Transport and Internal Trade": "transport-canada",
  "President of the King\u2019s Privy Council for Canada and Minister responsible for Canada-U.S. Trade, Intergovernmental Affairs and One Canadian Economy": "privy-council-office-intergovernmental-affairs-secretariat",
  "Minister of Artificial Intelligence and Digital Innovation": "artificial-intelligence-and-digital-innovation",
  "Minister of Energy and Natural Resources": "natural-resources-canada",
  "Minister of Health": "health-canada",
  "Secretary of State (Labour)": "employment-and-social-development-canada",
  "Minister of Canadian Identity and Culture": "canadian-heritage",
  "Minister of Justice and Attorney General of Canada": "justice-canada",
  "Minister of Housing and Infrastructure": "infrastructure-canada",
  "Secretary of State (Combatting Crime)": "public-safety-canada",
  "Secretary of State (Small Business and Tourism)": "innovation-science-and-economic-development-canada",
  "Minister of Government Transformation, Public Works and Procurement": "public-services-and-procurement-canada",
  "Secretary of State (Nature)": "environment-and-climate-change-canada",
  "Minister of Agriculture and Agri-Food": "agriculture-and-agri-food-canada",
  "Minister of Emergency Management and Community Resilience": "emergency-preparedness-canada",
  "Leader of the Government in the House of Commons": nil,
  "Secretary of State (Canada Revenue Agency and Financial Institutions)": "canada-revenue-agency",
  "Minister of Northern and Arctic Affairs": "crown-indigenous-relations-and-northern-affairs-canada",
  "Minister of Women and Gender Equality": "women-and-gender-equality-canada",
  "Secretary of State (Seniors)": "employment-and-social-development-canada",
  "Secretary of State (International Development)": "global-affairs-canada",
  "Minister of Fisheries": "fisheries-and-oceans-canada",
  "Minister of International Trade": "global-affairs-canada",
  "Minister of Veterans Affairs": "veterans-affairs-canada",
  "Secretary of State (Rural Development)": "rural-economic-development",
  "Minister responsible for the Atlantic Canada Opportunities Agency": "atlantic-canada-opportunities-agency",
  "Minister responsible for Canada Economic Development for Quebec Regions": "canada-economic-development-for-quebec-regions",
  "Minister responsible for Pacific Economic Development Canada": "federal-economic-development-agency-for-southern-ontario",
  "Minister of Northern and Arctic Affairs and Minister responsible for the Canadian Northern Economic Development Agency": "crown-indigenous-relations-and-northern-affairs-canada",
  "Prime Minister": "prime-minister-office"
  }.freeze

Promise.includes(:department_promises).find_each(batch_size: 100) do |promise|
  next if promise.relevant_departments.blank?

  relevant_departments = promise.relevant_departments

    relevant_departments&.each do |department|
      dept_slug = MAPPING[department.to_sym]
      dept = Department.find_by(slug: dept_slug)

      if dept.present?
        promise.link_department!(dept, is_lead: false)
      else
        Rails.logger.warn("No department found for relevant department: #{department}")
      end
    end

    # Do lead department last otherwise, it could be overwritten by relevant departments
    dept_slug = MAPPING[promise.responsible_department_lead&.to_sym]
    dept = Department.find_by(slug: dept_slug)
    if dept.present?
      promise.link_department!(dept, is_lead: true)
    else
      Rails.logger.warn("No department found for lead department: #{promise.responsible_department_lead}")
    end
end

puts "Completed seeding DepartmentPromises"
