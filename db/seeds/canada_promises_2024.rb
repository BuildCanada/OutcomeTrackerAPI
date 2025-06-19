require 'json'


promise_data = File.read('db/seeds/canada_promises_2024.jsonl')


def parse_firebase_timestamp(ts)
  return nil if ts.nil?

  return Time.parse(ts) if ts.is_a?(String)

  secs = ts["_seconds"]
  nsec = ts["_nanoseconds"]
  # Ruby ≥2.7: interpret second arg as nanoseconds
  time = Time.at(secs, nsec, :nsec)
  time.in_time_zone # converts to Rails.application.config.time_zone
end


promises = promise_data.split("\n").map do |line|
  data = JSON.parse(line)

  {
    promise_id: data['id'],
    text: data['canonical_commitment_text'],
    action_type_classified_at: parse_firebase_timestamp(data["action_type_classified_at"]),
    action_type_confidence: data["action_type_confidence"],
    action_type_rationale: data["action_type_rationale"],
    background_and_context: data["background_and_context"],
    bc_priority_score: data["bc_priority_score"],
    bc_promise_direction: data["bc_promise_direction"],
    bc_promise_rank: data["bc_promise_rank"],
    bc_promise_rank_rationale: data["bc_promise_rank_rationale"],
    bc_ranked_at: parse_firebase_timestamp(data["bc_ranked_at"]),
    candidate_or_government: data["candidate_or_government"],
    category: data["category"],
    concise_title: data["concise_title"],
    date_issued: data["date_issued"],
    description: data["description"],
    evidence_count: data["evidence_count"],
    evidence_sync_fixed_at: parse_firebase_timestamp(data["evidence_sync_fixed_at"]),
    explanation_enriched_at: parse_firebase_timestamp(data["explanation_enriched_at"]),
    explanation_enrichment_model: data["explanation_enrichment_model"],
    explanation_enrichment_status: data["explanation_enrichment_status"],
    history_generated_at: parse_firebase_timestamp(data["history_generated_at"]),
    implied_action_type: data["implied_action_type"],
    ingested_at: parse_firebase_timestamp(data["ingested_at"]),
    keywords_context_used: data["keywords_context_used"],
    keywords_enriched_at: parse_firebase_timestamp(data["keywords_enriched_at"]),
    keywords_enrichment_status: data["keywords_enrichment_status"],
    keywords_extracted_at: parse_firebase_timestamp(data["keywords_extracted_at"]),
    last_enrichment_at: parse_firebase_timestamp(data["last_enrichment_at"]),
    last_evidence_date: parse_firebase_timestamp(data["last_evidence_date"]),
    last_progress_update_at: parse_firebase_timestamp(data["last_progress_update_at"]),
    last_scored_at: parse_firebase_timestamp(data["last_scored_at"]),
    last_updated_at: parse_firebase_timestamp(data["last_updated_at"]),
    linking_preprocessing_done_at: parse_firebase_timestamp(data["linking_preprocessing_done_at"]),
    linking_processed_at: parse_firebase_timestamp(data["linking_processed_at"]),
    linking_status: data["linking_status"],
    migration_status_ed_at: parse_firebase_timestamp(data["migration_status_ed_at"]),
    migration_version: data["migration_version"],
    parliament_session_id: data["parliament_session_id"],
    party: data["party"],
    party_code: data["party_code"],
    progress_score: data["progress_score"],
    progress_score_1_to_5: data["progress_score_1_to_5"],
    progress_scoring_model: data["progress_scoring_model"],
    progress_status: data["progress_status"],
    progress_summary: data["progress_summary"],
    rationale_format_fixed_at: parse_firebase_timestamp(data["rationale_format_fixed_at"]),
    region_code: data["region_code"],
    responsible_department_lead: data["responsible_department_lead"],
    scoring_method: data["scoring_method"],
    scoring_model: data["scoring_model"],
    source_document_url: data["source_document_url"],
    source_type: data["source_type"],
    status: data["status"],
    what_it_means_for_canadians: data["what_it_means_for_canadians"],
    extracted_keywords_concepts: data["extracted_keywords_concepts"],
    intended_impact_and_objectives: data["intended_impact_and_objectives"],
    relevant_departments: data["relevant_departments"],
    linked_evidence_ids: data["linked_evidence_ids"],

    commitment_history_rationale: data["commitment_history_rationale"],
    key_points: data["key_points"],
    policy_areas: data["policy_areas"],
    target_groups: data["target_groups"]
  }
end

promises.each do |promise|
  Promise.find_or_create_by!(promise_id: promise[:promise_id]) do |e|
    e.assign_attributes(promise)
  end
end
