# Frontend Backend Requirements

What needs to be added to the backend to support the frontend views.

---

## 1. Home Page -- Burndown Chart

**Gap:** No historical record of when commitment statuses change. You can't draw a burndown without time-series data.

**Need:**

### New table: `commitment_status_changes`

| Column | Type | Notes |
|---|---|---|
| `commitment_id` | bigint FK | |
| `previous_status` | integer | enum matching `Commitment.statuses` |
| `new_status` | integer | enum matching `Commitment.statuses` |
| `changed_at` | datetime | when the transition happened |
| `reason` | text | optional, what triggered it |

Plus a callback on `Commitment` that creates a record whenever `status` changes.

### Commitment count snapshots

For the "increases in workload" part of the burndown -- you need to know when new commitments were added. `commitments.created_at` covers this already, but you may want a materialized endpoint.

### New API endpoint: `GET /api/burndown`

Returns time-series data: for each date, the count of commitments in each status bucket. Query would aggregate `commitment_status_changes` + `commitments.created_at`.

---

## 2. Home Page -- At a Glance Grid

**Gap:** No display ordering on policy areas. Index endpoint has no grouping.

**Need:**

### Migration: add `position` to `policy_areas`

For ordering sections in the grid.

### New API endpoint: `GET /api/dashboard/at_a_glance`

Returns commitments grouped by policy area, each with:
- Policy area name, slug, position
- Array of commitments with: id, title, status, commitment_type, lead_department name
- Summary counts per status

This is mostly a query concern -- the data model is already there.

---

## 3. Explore Tab -- Search & Filter

**Gap:** `CommitmentsController#index` returns `Commitment.all` with zero filtering, no pagination, no search.

**Need:**

### Upgrade `GET /commitments` endpoint with:

- **Full-text search** on `title` + `description` (pg_trgm or `tsearch`)
- **Filters:** `policy_area_id`, `status`, `commitment_type`, `department_id`, `party_code`, `region_code`
- **Sorting:** by status, date_promised, last_assessed_at, title
- **Pagination:** cursor or page-based

### Migration (optional): add GIN index for full-text search

```sql
ADD INDEX index_commitments_on_search ON commitments
  USING gin(to_tsvector('english', title || ' ' || description))
```

---

## 4. Commitment Detail -- Timeline

**Gap:** No unified timeline of events for a commitment. Criterion assessments have dates, but there's no concept of "milestones" or "events" tied to a commitment.

**Need:**

### New table: `commitment_events`

| Column | Type | Notes |
|---|---|---|
| `commitment_id` | bigint FK | |
| `event_type` | integer enum | `promised`, `mentioned`, `legislative_action`, `funding_allocated`, `status_change`, `criterion_assessed`, `superseded` |
| `title` | string | Short description |
| `description` | text | Detail |
| `occurred_at` | date | When it happened |
| `source_id` | bigint FK (optional) | Link to the source document |
| `metadata` | jsonb | Flexible data |

This consolidates timeline data from multiple places (commitment_sources dates, criterion_assessments, status changes) into one queryable table. Could be populated by callbacks or by the assessment pipeline.

### API: nested in `GET /commitments/:id`

Add a `timeline` array to the show response, ordered by `occurred_at`.

---

## 5. Commitment Detail -- Talk vs. Changed

**Gap:** No link between the activity/entry pipeline and commitments. The existing `Activity -> Evidence -> Promise` pipeline doesn't connect to `Commitment`. No classification of evidence as rhetoric vs. concrete action.

**Need:**

This is the `CommitmentMatch` from the evaluation plan, plus a classification layer.

### Extend `commitment_events` (or `commitment_matches`) with:

- `action_type` enum: `announcement` (talk) vs `concrete_action` (changed)
  - Announcement: press conference, speech, debate mention
  - Concrete: bill introduced/passed, OIC signed, budget line item, regulation gazetted

The assessment pipeline's small model can classify this during relevance filtering. The source_type on the linked Source already gives a strong signal (e.g., `press_conference` = talk, `order_in_council` = action).

### API: nested in commitment show

Two arrays: `announcements` and `actions`, each with date, title, source reference.

---

## 6. Commitment Detail -- Drift

**Gap:** `superseded_by_id` only tracks full replacement. No tracking of how the _same_ commitment's language, scope, or targets shifted over time.

**Need:**

### New table: `commitment_revisions`

| Column | Type | Notes |
|---|---|---|
| `commitment_id` | bigint FK | |
| `title` | string | Title at this point in time |
| `description` | text | Description at this point |
| `original_text` | text | Source text at this point |
| `target_date` | date | Target at this point |
| `source_id` | bigint FK (optional) | What document introduced this change |
| `change_summary` | text | LLM-generated summary of what changed |
| `revision_date` | date | When this version was observed |
| `created_at` | datetime | |

Before updating a commitment's text/scope, snapshot the current state. The diff between revisions = the drift.

### API: nested in commitment show

`revisions` array ordered by `revision_date`, each with a `change_summary` explaining what shifted.

---

## 7. Feed View -- Activity Feed + RSS

**Gap:** No unified feed of activity across commitments. No RSS output.

**Need:**

### New table: `feed_items`

| Column | Type | Notes |
|---|---|---|
| `feedable_type` | string | Polymorphic: `CriterionAssessment`, `CommitmentEvent`, `CommitmentRevision`, `CommitmentStatusChange` |
| `feedable_id` | bigint | |
| `commitment_id` | bigint FK | For filtering |
| `policy_area_id` | bigint FK (nullable) | Denormalized for fast filtering |
| `event_type` | string | `status_change`, `criterion_assessed`, `drift`, `new_evidence`, etc. |
| `title` | string | Display title |
| `summary` | text | Short description |
| `occurred_at` | datetime | |
| `created_at` | datetime | |

Populated by callbacks on the source models. Denormalized for fast querying.

### New API endpoints:

- `GET /feed` -- paginated, filterable by `commitment_id`, `policy_area_id`, `event_type`, date range
- `GET /feed.rss` -- RSS 2.0 output, same filters via query params
- `GET /commitments/:id/feed` -- scoped to one commitment
- `GET /commitments/:id/feed.rss`

### RSS generation

Use the `rss` stdlib or a gem like `builder` to generate XML. Rails `respond_to` block with `format.rss`.

---

## Summary: New Tables

| Table | Purpose |
|---|---|
| `commitment_status_changes` | Burndown chart history |
| `commitment_events` | Timeline + talk vs. changed |
| `commitment_revisions` | Drift tracking |
| `feed_items` | Unified activity feed + RSS |

## Summary: Modified Models

| Model | Changes |
|---|---|
| `Commitment` | `after_update` callback for status changes, `has_many` for events/revisions/status_changes/feed_items |
| `PolicyArea` | Add `position` column |
| `CriterionAssessment` | `after_create` callback to generate feed_item |

## Summary: New/Modified Endpoints

| Endpoint | Purpose |
|---|---|
| `GET /api/burndown` | Time-series status data for chart |
| `GET /api/dashboard/at_a_glance` | Commitments grouped by policy area |
| `GET /commitments` (upgraded) | Search, filter, paginate |
| `GET /commitments/:id` (upgraded) | Add timeline, talk/changed, drift, feed |
| `GET /feed` + `GET /feed.rss` | Global activity feed |
| `GET /commitments/:id/feed(.rss)` | Per-commitment feed |

## Dependencies on Evaluation Pipeline

The "talk vs. changed" and "timeline" views get much richer once the `CommitmentMatch` pipeline from the evaluation plan is running. The `commitment_events` table is essentially the frontend-facing materialization of what that pipeline produces. Build `commitment_status_changes` and `commitment_revisions` first (they're independent), then wire `commitment_events` and `feed_items` to the assessment pipeline as it comes online.
