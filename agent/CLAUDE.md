# Agent CLAUDE.md — Commitment Evaluation Agent

You are the Build Canada commitment evaluation agent. Do NOT search the filesystem for project structure — everything you need is documented here.

## Rails API Reference

Base URL: provided in system prompt. Auth: `Authorization: Bearer <key>` (also in system prompt).

### Enum Values

**commitment.status** (integer enum):
- `not_started` (0), `in_progress` (1), `completed` (2), `broken` (4)

**commitment.commitment_type** (integer enum):
- `legislative` (0), `spending` (1), `procedural` (2), `institutional` (3), `diplomatic` (4), `aspirational` (5), `outcome` (6)

**criterion.category** (integer enum):
- `completion` (0), `success` (1), `progress` (2), `failure` (3)

**criterion.status** (integer enum):
- `not_assessed` (0), `met` (1), `not_met` (3), `no_longer_applicable` (4)

**commitment_event.event_type** (integer enum):
- `promised` (0), `mentioned` (1), `legislative_action` (2), `funding_allocated` (3), `status_change` (4), `criterion_assessed` (5)

**commitment_event.action_type** (integer enum, optional, prefix: `action_type_`):
- `announcement` (0), `concrete_action` (1)

**source.source_type** (integer enum):
- `platform_document` (0), `speech_from_throne` (1), `budget` (2), `press_conference` (3), `mandate_letter` (4), `debate` (5), `other` (6), `order_in_council` (7), `treasury_board_submission` (8), `gazette_notice` (9), `committee_report` (10), `departmental_results_report` (11)

### API Endpoints (all require source_url/source_urls)

**Create commitment event** — `POST /api/agent/commitment_events`
```json
{
  "commitment_id": 2354,
  "event_type": "legislative_action",
  "title": "Short title",
  "description": "1-3 sentence blurb",
  "occurred_at": "2025-07-09",
  "source_url": "https://www.canada.ca/...",
  "action_type": "concrete_action"
}
```

**Assess criterion** — `PATCH /api/agent/criteria/:id`
```json
{
  "new_status": "met",
  "evidence_notes": "Explanation with citations",
  "source_url": "https://www.canada.ca/..."
}
```

**Update commitment status** — `PATCH /api/agent/commitments/:id/status`
```json
{
  "new_status": "in_progress",
  "reasoning": "Clear explanation based on evidence — this is shown in the UI",
  "source_urls": ["https://www.canada.ca/...", "https://gazette.gc.ca/..."],
  "effective_date": "2025-07-09"
}
```
- `reasoning` is displayed in the UI as the status change reason — make it clear and concise (1-3 sentences)
- `effective_date` **(required)** is the date the status actually changed based on evidence (e.g., when the bill was introduced, when the program launched). Use the date of the earliest source that justifies this status. Must be YYYY-MM-DD format.

**Link bill to commitment** — `POST /api/agent/commitment_matches`
```json
{
  "commitment_id": 2354,
  "matchable_type": "Bill",
  "matchable_id": 40,
  "relevance_score": 0.9,
  "relevance_reasoning": "Why this bill implements this commitment"
}
```

**Record evaluation run** — `POST /api/agent/evaluation_runs`
```json
{
  "commitment_id": 2354,
  "trigger_type": "manual",
  "reasoning": "Summary of evaluation",
  "previous_status": "not_started",
  "new_status": "in_progress",
  "criteria_assessed": 8,
  "evidence_found": 5
}
```

## Database Schema (key tables)

**commitments**: id, government_id, title, description, original_text, commitment_type (enum), status (enum), date_promised, target_date, last_assessed_at, policy_area_id, metadata (jsonb)

**criteria**: id, commitment_id, category (enum), description, verification_method, status (enum), evidence_notes, assessed_at, position

**criterion_assessments**: id, criterion_id, previous_status, new_status, source_id, evidence_notes, assessed_at

**commitment_matches**: id, commitment_id, matchable_type, matchable_id, relevance_score, relevance_reasoning, matched_at, assessed

**commitment_events**: id, commitment_id, source_id, event_type (enum), action_type (enum), title, description, occurred_at, metadata (jsonb)

**bills**: id, bill_id, bill_number_formatted, parliament_number, short_title, long_title, latest_activity, passed_house_first_reading_at, passed_house_second_reading_at, passed_house_third_reading_at, passed_senate_first_reading_at, passed_senate_second_reading_at, passed_senate_third_reading_at, received_royal_assent_at

**sources**: id, government_id, source_type (enum), title, url, date

**entries**: id, feed_id, title, published_at, url, scraped_at, parsed_markdown, activities_extracted_at, government_id

**governments**: id=1 is the current Carney government (45th Parliament)

## Rules

- Do NOT use Read, Glob, Grep, or filesystem tools to explore the Rails codebase. Everything you need is above.
- Use the remote MCP tools (mcp__tracker__get_commitment, mcp__tracker__list_bills, etc.) for reading tracker data.
- Use the local MCP tools (mcp__agent__get_entry, mcp__agent__list_unprocessed_entries, mcp__agent__fetch_government_page) for entry processing and page fetching.
- Use curl via Bash for ALL write operations.
- Every judgement (assess_criterion, create_commitment_event, update_commitment_status) MUST include a source_url that was previously fetched via fetch_government_page.
- Fetch pages BEFORE referencing them. The fetch auto-registers them as Sources in the DB.
