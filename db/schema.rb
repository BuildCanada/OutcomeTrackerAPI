# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_06_23_150313) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "activities", force: :cascade do |t|
    t.bigint "entry_id", null: false
    t.bigint "government_id", null: false
    t.string "title"
    t.string "summary"
    t.string "source_url"
    t.jsonb "info"
    t.datetime "published_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["entry_id"], name: "index_activities_on_entry_id"
    t.index ["government_id"], name: "index_activities_on_government_id"
  end

  create_table "chats", force: :cascade do |t|
    t.string "model_id"
    t.bigint "record_id"
    t.string "record_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "json_attributes"
    t.string "type"
  end

  create_table "department_promises", force: :cascade do |t|
    t.bigint "department_id", null: false
    t.bigint "promise_id", null: false
    t.boolean "is_lead", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["department_id"], name: "index_department_promises_on_department_id"
    t.index ["promise_id"], name: "index_department_promises_on_promise_id"
  end

  create_table "departments", force: :cascade do |t|
    t.bigint "government_id", null: false
    t.string "slug", null: false
    t.string "official_name", null: false
    t.string "display_name", null: false
    t.integer "priority", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["government_id"], name: "index_departments_on_government_id"
    t.index ["slug"], name: "index_departments_on_slug"
  end

  create_table "entries", force: :cascade do |t|
    t.bigint "feed_id", null: false
    t.string "title"
    t.datetime "published_at", precision: nil
    t.string "external_id"
    t.string "url"
    t.datetime "scraped_at", precision: nil
    t.string "summary"
    t.bigint "government_id", null: false
    t.jsonb "raw"
    t.string "raw_html"
    t.string "parsed_html"
    t.string "parsed_markdown"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "activities_extracted_at", precision: nil
    t.boolean "is_index"
    t.bigint "parent_id"
    t.datetime "skipped_at", precision: nil
    t.string "skip_reason"
    t.index ["feed_id"], name: "index_entries_on_feed_id"
    t.index ["government_id"], name: "index_entries_on_government_id"
    t.index ["parent_id"], name: "index_entries_on_parent_id"
  end

  create_table "evidences", force: :cascade do |t|
    t.bigint "activity_id", null: false
    t.bigint "promise_id", null: false
    t.string "impact"
    t.integer "impact_magnitude"
    t.string "impact_reason"
    t.datetime "linked_at", precision: nil
    t.bigint "linked_by_id"
    t.string "link_type"
    t.string "link_reason"
    t.boolean "review"
    t.bigint "reviewed_by_id"
    t.datetime "reviewed_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["activity_id"], name: "index_evidences_on_activity_id"
    t.index ["linked_by_id"], name: "index_evidences_on_linked_by_id"
    t.index ["promise_id"], name: "index_evidences_on_promise_id"
    t.index ["reviewed_by_id"], name: "index_evidences_on_reviewed_by_id"
  end

  create_table "feeds", force: :cascade do |t|
    t.string "title"
    t.text "description"
    t.string "language"
    t.string "url"
    t.jsonb "raw"
    t.bigint "government_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "last_scraped_at", precision: nil
    t.string "error_message"
    t.datetime "last_scrape_failed_at", precision: nil
    t.index ["government_id"], name: "index_feeds_on_government_id"
  end

  create_table "good_job_batches", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "description"
    t.jsonb "serialized_properties"
    t.text "on_finish"
    t.text "on_success"
    t.text "on_discard"
    t.text "callback_queue_name"
    t.integer "callback_priority"
    t.datetime "enqueued_at"
    t.datetime "discarded_at"
    t.datetime "finished_at"
    t.datetime "jobs_finished_at"
  end

  create_table "good_job_executions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "active_job_id", null: false
    t.text "job_class"
    t.text "queue_name"
    t.jsonb "serialized_params"
    t.datetime "scheduled_at"
    t.datetime "finished_at"
    t.text "error"
    t.integer "error_event", limit: 2
    t.text "error_backtrace", array: true
    t.uuid "process_id"
    t.interval "duration"
    t.index ["active_job_id", "created_at"], name: "index_good_job_executions_on_active_job_id_and_created_at"
    t.index ["process_id", "created_at"], name: "index_good_job_executions_on_process_id_and_created_at"
  end

  create_table "good_job_processes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "state"
    t.integer "lock_type", limit: 2
  end

  create_table "good_job_settings", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "key"
    t.jsonb "value"
    t.index ["key"], name: "index_good_job_settings_on_key", unique: true
  end

  create_table "good_jobs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "queue_name"
    t.integer "priority"
    t.jsonb "serialized_params"
    t.datetime "scheduled_at"
    t.datetime "performed_at"
    t.datetime "finished_at"
    t.text "error"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "active_job_id"
    t.text "concurrency_key"
    t.text "cron_key"
    t.uuid "retried_good_job_id"
    t.datetime "cron_at"
    t.uuid "batch_id"
    t.uuid "batch_callback_id"
    t.boolean "is_discrete"
    t.integer "executions_count"
    t.text "job_class"
    t.integer "error_event", limit: 2
    t.text "labels", array: true
    t.uuid "locked_by_id"
    t.datetime "locked_at"
    t.index ["active_job_id", "created_at"], name: "index_good_jobs_on_active_job_id_and_created_at"
    t.index ["batch_callback_id"], name: "index_good_jobs_on_batch_callback_id", where: "(batch_callback_id IS NOT NULL)"
    t.index ["batch_id"], name: "index_good_jobs_on_batch_id", where: "(batch_id IS NOT NULL)"
    t.index ["concurrency_key", "created_at"], name: "index_good_jobs_on_concurrency_key_and_created_at"
    t.index ["concurrency_key"], name: "index_good_jobs_on_concurrency_key_when_unfinished", where: "(finished_at IS NULL)"
    t.index ["cron_key", "created_at"], name: "index_good_jobs_on_cron_key_and_created_at_cond", where: "(cron_key IS NOT NULL)"
    t.index ["cron_key", "cron_at"], name: "index_good_jobs_on_cron_key_and_cron_at_cond", unique: true, where: "(cron_key IS NOT NULL)"
    t.index ["finished_at"], name: "index_good_jobs_jobs_on_finished_at", where: "((retried_good_job_id IS NULL) AND (finished_at IS NOT NULL))"
    t.index ["labels"], name: "index_good_jobs_on_labels", where: "(labels IS NOT NULL)", using: :gin
    t.index ["locked_by_id"], name: "index_good_jobs_on_locked_by_id", where: "(locked_by_id IS NOT NULL)"
    t.index ["priority", "created_at"], name: "index_good_job_jobs_for_candidate_lookup", where: "(finished_at IS NULL)"
    t.index ["priority", "created_at"], name: "index_good_jobs_jobs_on_priority_created_at_when_unfinished", order: { priority: "DESC NULLS LAST" }, where: "(finished_at IS NULL)"
    t.index ["priority", "scheduled_at"], name: "index_good_jobs_on_priority_scheduled_at_unfinished_unlocked", where: "((finished_at IS NULL) AND (locked_by_id IS NULL))"
    t.index ["queue_name", "scheduled_at"], name: "index_good_jobs_on_queue_name_and_scheduled_at", where: "(finished_at IS NULL)"
    t.index ["scheduled_at"], name: "index_good_jobs_on_scheduled_at", where: "(finished_at IS NULL)"
  end

  create_table "governments", force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "messages", force: :cascade do |t|
    t.bigint "chat_id", null: false
    t.string "role"
    t.text "content"
    t.string "model_id"
    t.integer "input_tokens"
    t.integer "output_tokens"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "tool_call_id"
    t.index ["chat_id"], name: "index_messages_on_chat_id"
    t.index ["tool_call_id"], name: "index_messages_on_tool_call_id"
  end

  create_table "ministers", force: :cascade do |t|
    t.bigint "government_id", null: false
    t.bigint "department_id", null: false
    t.integer "order_of_precedence", null: false
    t.string "person_short_honorific", null: false
    t.datetime "started_at", precision: nil, null: false
    t.datetime "ended_at", precision: nil
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.string "title", null: false
    t.string "avatar_url"
    t.string "role", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["department_id"], name: "index_ministers_on_department_id"
    t.index ["government_id"], name: "index_ministers_on_government_id"
  end

  create_table "promises", force: :cascade do |t|
    t.string "promise_id"
    t.datetime "action_type_classified_at"
    t.integer "action_type_confidence"
    t.text "action_type_rationale"
    t.text "background_and_context"
    t.integer "bc_priority_score"
    t.string "bc_promise_direction"
    t.string "bc_promise_rank"
    t.text "bc_promise_rank_rationale"
    t.datetime "bc_ranked_at"
    t.string "candidate_or_government"
    t.string "category"
    t.string "concise_title"
    t.date "date_issued"
    t.text "description"
    t.integer "evidence_count"
    t.datetime "evidence_sync_fixed_at"
    t.datetime "explanation_enriched_at"
    t.string "explanation_enrichment_model"
    t.string "explanation_enrichment_status"
    t.datetime "history_generated_at"
    t.string "implied_action_type"
    t.datetime "ingested_at"
    t.string "keywords_context_used"
    t.datetime "keywords_enriched_at"
    t.string "keywords_enrichment_status"
    t.datetime "keywords_extracted_at"
    t.datetime "last_enrichment_at"
    t.datetime "last_evidence_date"
    t.datetime "last_progress_update_at"
    t.datetime "last_scored_at"
    t.datetime "last_updated_at"
    t.datetime "linking_preprocessing_done_at"
    t.datetime "linking_processed_at"
    t.string "linking_status"
    t.datetime "migration_status_ed_at"
    t.string "migration_version"
    t.string "parliament_session_id"
    t.string "party"
    t.string "party_code"
    t.integer "progress_score"
    t.integer "progress_score_1_to_5"
    t.string "progress_scoring_model"
    t.string "progress_status"
    t.text "progress_summary"
    t.datetime "rationale_format_fixed_at"
    t.string "region_code"
    t.string "responsible_department_lead"
    t.string "scoring_method"
    t.string "scoring_model"
    t.string "source_document_url"
    t.string "source_type"
    t.string "status"
    t.text "text"
    t.text "extracted_keywords_concepts", default: [], array: true
    t.text "intended_impact_and_objectives", default: [], array: true
    t.text "what_it_means_for_canadians", default: [], array: true
    t.text "linked_evidence_ids", default: [], array: true
    t.text "relevant_departments", default: [], array: true
    t.jsonb "commitment_history_rationale", default: {}
    t.jsonb "commitment_history_timeline", default: {}
    t.jsonb "key_points", default: {}
    t.jsonb "policy_areas", default: {}
    t.jsonb "target_groups", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "tool_calls", force: :cascade do |t|
    t.bigint "message_id", null: false
    t.string "tool_call_id"
    t.string "name"
    t.jsonb "arguments"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["message_id"], name: "index_tool_calls_on_message_id"
    t.index ["tool_call_id"], name: "index_tool_calls_on_tool_call_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.string "role", default: "user", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "activities", "entries"
  add_foreign_key "activities", "governments"
  add_foreign_key "department_promises", "departments"
  add_foreign_key "department_promises", "promises"
  add_foreign_key "departments", "governments"
  add_foreign_key "entries", "entries", column: "parent_id"
  add_foreign_key "entries", "feeds"
  add_foreign_key "entries", "governments"
  add_foreign_key "evidences", "activities"
  add_foreign_key "evidences", "promises"
  add_foreign_key "evidences", "users", column: "linked_by_id"
  add_foreign_key "evidences", "users", column: "reviewed_by_id"
  add_foreign_key "feeds", "governments"
  add_foreign_key "messages", "chats"
  add_foreign_key "messages", "tool_calls"
  add_foreign_key "ministers", "departments"
  add_foreign_key "ministers", "governments"
  add_foreign_key "tool_calls", "messages"
end
