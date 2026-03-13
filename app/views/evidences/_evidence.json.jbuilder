json.(evidence,
  :id,
  :impact,
  :impact_magnitude,
  :impact_reason
)


json.(evidence.activity,
  :title,
  :summary,
  :published_at,
)

json.source_url evidence.activity.entry.url
