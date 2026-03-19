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
        json.(assessment.source, :id, :title, :source_type, :url, :date)
      end
    end
  end
end

json.departments @commitment.commitment_departments do |cd|
  json.id cd.department.id
  json.display_name cd.department.display_name
  json.slug cd.department.slug
  json.is_lead cd.is_lead
end

if @commitment.lead_department
  json.lead_department do
    json.(@commitment.lead_department, :id, :display_name, :slug)
  end
end

json.timeline @commitment.events.order(:occurred_at) do |event|
  json.(event, :id, :event_type, :action_type, :title, :description, :occurred_at)
  if event.source
    json.source do
      json.(event.source, :id, :title, :source_type, :url, :date)
    end
  end
end

json.announcements @commitment.announcements do |event|
  json.(event, :id, :title, :description, :occurred_at)
  if event.source
    json.source do
      json.(event.source, :id, :title, :source_type, :url, :date)
    end
  end
end

json.actions @commitment.actions do |event|
  json.(event, :id, :title, :description, :occurred_at)
  if event.source
    json.source do
      json.(event.source, :id, :title, :source_type, :url, :date)
    end
  end
end

json.revisions @commitment.revisions.order(:revision_date) do |revision|
  json.(revision, :id, :title, :description, :original_text, :target_date, :change_summary, :revision_date)
  if revision.source
    json.source do
      json.(revision.source, :id, :title, :source_type, :url, :date)
    end
  end
end

json.status_history @commitment.status_changes.includes(:source).order(:changed_at) do |sc|
  json.(sc, :id, :previous_status, :new_status, :changed_at, :reason)
  if sc.source
    json.source do
      json.(sc.source, :id, :title, :source_type, :url, :date)
    end
  end
end

json.recent_feed @commitment.feed_items.newest_first.limit(20) do |fi|
  json.(fi, :id, :event_type, :title, :summary, :occurred_at)
end
