json.(@commitment,
  :id,
  :title,
  :description,
  :original_text,
  :commitment_type,
  :status,
  :date_promised,
  :target_date,
  :last_assessed_at,
  :region_code,
  :party_code,
  :metadata
)

if @commitment.policy_area
  json.policy_area do
    json.(@commitment.policy_area, :id, :name, :slug)
  end
end

json.government do
  json.(@commitment.government, :id, :name, :slug)
end

if @commitment.parent
  json.parent do
    json.(@commitment.parent, :id, :title)
  end
end

if @commitment.superseded_by
  json.superseded_by do
    json.(@commitment.superseded_by, :id, :title)
  end
end

json.supersedes @commitment.supersedes, :id, :title, :status

json.children @commitment.children, :id, :title, :status

json.sources @commitment.commitment_sources.includes(:source) do |cs|
  json.(cs, :id, :section, :reference, :excerpt)
  json.source do
    json.(cs.source, :id, :source_type, :title, :url, :date)
  end
end

json.criteria @commitment.criteria.order(:category, :position) do |criterion|
  json.(criterion, :id, :category, :description, :verification_method, :status, :evidence_notes, :assessed_at, :position)

  json.assessments criterion.criterion_assessments.order(assessed_at: :desc).limit(5) do |assessment|
    json.(assessment, :id, :previous_status, :new_status, :evidence_notes, :assessed_at)
    if assessment.source
      json.source do
        json.(assessment.source, :id, :title, :source_type)
      end
    end
  end
end

json.departments @commitment.commitment_departments do |cd|
  json.id cd.department.id
  json.display_name cd.department.display_name
  json.is_lead cd.is_lead
end

if @commitment.lead_department
  json.lead_department do
    json.(@commitment.lead_department, :id, :display_name)
  end
end
