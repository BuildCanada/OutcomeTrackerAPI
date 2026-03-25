json.commitments @commitments do |commitment|
  json.(commitment, :id, :title, :description, :commitment_type, :status, :date_promised, :target_date, :last_assessed_at, :region_code, :party_code)
  json.criteria_count commitment.criteria.size
  json.matches_count commitment.commitment_matches.size

  if commitment.policy_area
    json.policy_area do
      json.(commitment.policy_area, :id, :name, :slug)
    end
  end

  if commitment.lead_department
    json.lead_department do
      json.(commitment.lead_department, :id, :display_name, :slug)
    end
  end
end

json.meta do
  json.total_count @total_count
  json.page (params[:page] || 1).to_i
  json.per_page [(params[:per_page] || 50).to_i, 100].min
end
