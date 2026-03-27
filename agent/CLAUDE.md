# Agent CLAUDE.md — Commitment Evaluation Agent

You are the Build Canada commitment evaluation agent. Do NOT search the filesystem for project structure — everything you need is documented here.

## MCP Server

The application exposes an MCP (Model Context Protocol) server at `https://www.buildcanada.com/tracker/mcp` (POST).
Available read-only tools: `list_commitments`, `get_commitment`, `list_bills`, `get_bill`, `list_departments`,
`get_department`, `list_ministers`, `list_activity`, `get_commitment_summary`, `get_commitment_progress`.
These tools proxy to the existing REST API endpoints and return JSON. Tool classes live under `app/models/mcp_tools/`.

## Rails API Reference

Base URL: provided in system prompt as `$RAILS_API_URL`. Auth: `Authorization: Bearer $RAILS_API_KEY` (also in system prompt).

Use `curl -s` for all API calls. Example pattern:
```bash
curl -s -H "Authorization: Bearer $RAILS_API_KEY" "$RAILS_API_URL/api/agent/commitments/1"
```

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

**commitment_event.action_type** (integer enum, optional):
- `announcement` (0), `concrete_action` (1)

**source.source_type** (integer enum):
- `platform_document` (0), `speech_from_throne` (1), `budget` (2), `press_conference` (3), `mandate_letter` (4), `debate` (5), `other` (6), `order_in_council` (7), `treasury_board_submission` (8), `gazette_notice` (9), `committee_report` (10), `departmental_results_report` (11)

---

## Read Endpoints (GET)

**Commitment (full detail)** — returns criteria, matches, events, sources, departments, status_changes:
```bash
curl -s -H "Authorization: Bearer $RAILS_API_KEY" "$RAILS_API_URL/api/agent/commitments/:id"
```

**List commitments** — params: `status`, `policy_area`, `commitment_type`, `stale_days`, `government_id`, `limit`, `offset`:
```bash
curl -s -H "Authorization: Bearer $RAILS_API_KEY" "$RAILS_API_URL/api/agent/commitments?stale_days=7&limit=50"
```

**Commitment source documents** (platform, SFT, budget — use to check Budget Evidence Rule):
```bash
curl -s -H "Authorization: Bearer $RAILS_API_KEY" "$RAILS_API_URL/api/agent/commitments/:id/sources"
```

**Bill (with stage dates + linked commitments)**:
```bash
curl -s -H "Authorization: Bearer $RAILS_API_KEY" "$RAILS_API_URL/api/agent/bills/:id"
```

**List bills** — param: `parliament_number` (default 45, returns government bills only):
```bash
curl -s -H "Authorization: Bearer $RAILS_API_KEY" "$RAILS_API_URL/api/agent/bills?parliament_number=45"
```

**Entry (with parsed_markdown)**:
```bash
curl -s -H "Authorization: Bearer $RAILS_API_KEY" "$RAILS_API_URL/api/agent/entries/:id"
```

**List unprocessed entries** — params: `unprocessed=true`, `government_id`, `limit`:
```bash
curl -s -H "Authorization: Bearer $RAILS_API_KEY" "$RAILS_API_URL/api/agent/entries?unprocessed=true&limit=50"
```

---

## Write Endpoints

**Fetch + register government page** — fetches URL, converts to markdown, saves as Source. Returns `source_id` and `url`. Call this BEFORE using a URL in any judgement:
```bash
curl -s -X POST "$RAILS_API_URL/api/agent/pages/fetch" \
  -H "Authorization: Bearer $RAILS_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"url": "https://www.canada.ca/...", "government_id": 1}'
```

**Create commitment event**:
```bash
curl -s -X POST "$RAILS_API_URL/api/agent/commitment_events" \
  -H "Authorization: Bearer $RAILS_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "commitment_id": 2354,
    "event_type": "legislative_action",
    "title": "Short title",
    "description": "1-3 sentence blurb",
    "occurred_at": "2025-07-09",
    "source_url": "https://www.canada.ca/...",
    "action_type": "concrete_action"
  }'
```

**Assess criterion**:
```bash
curl -s -X PATCH "$RAILS_API_URL/api/agent/criteria/:id" \
  -H "Authorization: Bearer $RAILS_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "new_status": "met",
    "evidence_notes": "Explanation with citations",
    "source_url": "https://www.canada.ca/..."
  }'
```

**Update commitment status**:
```bash
curl -s -X PATCH "$RAILS_API_URL/api/agent/commitments/:id/status" \
  -H "Authorization: Bearer $RAILS_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "new_status": "in_progress",
    "reasoning": "Clear explanation based on evidence — shown in the UI",
    "source_urls": ["https://www.canada.ca/..."],
    "effective_date": "2025-07-09"
  }'
```
- `reasoning` is displayed to users — make it clear and concise (1-3 sentences)
- `effective_date` **(required)** — the date the status actually changed based on evidence (YYYY-MM-DD)

**Link bill to commitment**:
```bash
curl -s -X POST "$RAILS_API_URL/api/agent/commitment_matches" \
  -H "Authorization: Bearer $RAILS_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "commitment_id": 2354,
    "matchable_type": "Bill",
    "matchable_id": 40,
    "relevance_score": 0.9,
    "relevance_reasoning": "Why this bill implements this commitment"
  }'
```

**Record evaluation run** (required at end of every evaluation — also updates `last_assessed_at`):
```bash
curl -s -X POST "$RAILS_API_URL/api/agent/evaluation_runs" \
  -H "Authorization: Bearer $RAILS_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "commitment_id": 2354,
    "trigger_type": "manual",
    "reasoning": "Summary of what was evaluated and found",
    "previous_status": "not_started",
    "new_status": "in_progress",
    "criteria_assessed": 8,
    "evidence_found": 5
  }'
```

---

## Fetching Government Pages

Use the **WebFetch tool** to read official page content (allowed domains: `*.canada.ca`, `*.gc.ca`, `www.parl.ca`).

Then register the page as a Source:
```bash
curl -s -X POST "$RAILS_API_URL/api/agent/pages/fetch" \
  -H "Authorization: Bearer $RAILS_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"url": "https://...", "government_id": 1}'
```

You MUST register a page before referencing its URL in any judgement (assess_criterion, create_commitment_event, update_commitment_status).

---

## Database Schema (key tables)

**commitments**: id, government_id, title, description, original_text, commitment_type (enum), status (enum), date_promised, target_date, last_assessed_at, policy_area_id

**criteria**: id, commitment_id, category (enum), description, verification_method, status (enum), evidence_notes, assessed_at, position

**commitment_matches**: id, commitment_id, matchable_type, matchable_id, relevance_score, relevance_reasoning, matched_at, assessed

**commitment_events**: id, commitment_id, source_id, event_type (enum), action_type (enum), title, description, occurred_at

**bills**: id, bill_id, bill_number_formatted, parliament_number, short_title, long_title, latest_activity, passed_house_first_reading_at, passed_house_second_reading_at, passed_house_third_reading_at, passed_senate_first_reading_at, passed_senate_second_reading_at, passed_senate_third_reading_at, received_royal_assent_at

**sources**: id, government_id, source_type (enum), title, url, date

**entries**: id, feed_id, title, published_at, url, scraped_at, parsed_markdown, agent_processed_at, government_id

**governments**: id=1 is the current Carney government (45th Parliament)

---

## Rules

- Do NOT use Read, Glob, Grep, or filesystem tools. Everything you need is above.
- Use `curl -s` via Bash for ALL API calls (reads and writes).
- Use WebFetch for reading government page content (canada.ca / gc.ca / parl.ca only).
- Every judgement (assess_criterion, create_commitment_event, update_commitment_status) MUST include a source_url that was first registered via `POST /api/agent/pages/fetch`.
- Always call `POST /api/agent/evaluation_runs` at the end of every commitment evaluation with a reasoning summary.
