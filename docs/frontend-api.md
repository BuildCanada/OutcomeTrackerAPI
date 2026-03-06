# Frontend API Implementation

Backend support for the commitment tracker frontend. Covers the home page (burndown + at-a-glance grid), the explore tab (search/filter/paginate), commitment detail pages (timeline, talk vs. changed, drift), and the activity feed with RSS.

---

## Data Model

### New Tables

Four new tables support the frontend views. All are populated automatically via ActiveRecord callbacks -- no manual creation needed.

#### `commitment_status_changes`

Audit log of every status transition on a commitment. Powers the burndown chart.

| Column | Type | Notes |
|---|---|---|
| `commitment_id` | bigint FK | |
| `previous_status` | integer | Enum matching `Commitment.statuses` |
| `new_status` | integer | Enum matching `Commitment.statuses` |
| `changed_at` | datetime | When the transition happened |
| `reason` | text | Optional explanation |

**Auto-populated:** An `after_update` callback on `Commitment` creates a record whenever `status` changes. Also creates a `FeedItem`.

#### `commitment_events`

Timeline entries for a commitment. Each event has both an `event_type` (what happened) and an optional `action_type` (talk vs. action classification).

| Column | Type | Notes |
|---|---|---|
| `commitment_id` | bigint FK | |
| `source_id` | bigint FK (optional) | Link to source document |
| `event_type` | integer enum | `promised`, `mentioned`, `legislative_action`, `funding_allocated`, `status_change`, `criterion_assessed`, `superseded` |
| `action_type` | integer enum (optional) | `announcement` (talk) or `concrete_action` (changed) |
| `title` | string | Short description |
| `description` | text | Detail |
| `occurred_at` | date | When it happened |
| `metadata` | jsonb | Flexible data |

**Not auto-populated.** Events are created by the assessment pipeline or manually. The `action_type` field is what powers the "talk vs. changed" view on commitment detail pages.

#### `commitment_revisions`

Snapshots of a commitment's previous state before it was modified. Powers the drift view.

| Column | Type | Notes |
|---|---|---|
| `commitment_id` | bigint FK | |
| `source_id` | bigint FK (optional) | Document that introduced the change |
| `title` | string | Title before the change |
| `description` | text | Description before the change |
| `original_text` | text | Original text before the change |
| `target_date` | date | Target date before the change |
| `change_summary` | text | LLM-generated or manual summary of what changed |
| `revision_date` | date | When this revision was captured |

**Auto-populated:** An `after_update` callback on `Commitment` snapshots the previous values whenever `title`, `description`, `original_text`, or `target_date` changes. The revision stores the **old** values, so comparing revisions chronologically shows drift. Also creates a `FeedItem`.

#### `feed_items`

Denormalized activity feed. Every notable event across the system creates a feed item via callbacks.

| Column | Type | Notes |
|---|---|---|
| `feedable_type` | string | Polymorphic source: `CommitmentStatusChange`, `CommitmentEvent`, `CommitmentRevision`, `CriterionAssessment` |
| `feedable_id` | bigint | |
| `commitment_id` | bigint FK | For filtering |
| `policy_area_id` | bigint FK (optional) | Denormalized from commitment for fast filtering |
| `event_type` | string | `status_change`, `event`, `drift`, `criterion_assessed` |
| `title` | string | Display title |
| `summary` | text | Short description |
| `occurred_at` | datetime | |

**Auto-populated:** `after_create` callbacks on `CommitmentStatusChange`, `CommitmentEvent`, `CommitmentRevision`, and `CriterionAssessment` each create a corresponding `FeedItem`.

### Schema Changes to Existing Tables

#### `policy_areas`

Added `position` column (integer, default 0). Controls display ordering in the at-a-glance grid. Set via Avo admin.

#### `commitments`

Added a GIN full-text search index on `title` and `description`:

```sql
CREATE INDEX index_commitments_on_search
ON commitments
USING gin(to_tsvector('english', coalesce(title, '') || ' ' || coalesce(description, '')))
```

### Model Changes

#### `Commitment`

New associations:

```ruby
has_many :status_changes, class_name: "CommitmentStatusChange"
has_many :events, class_name: "CommitmentEvent"
has_many :revisions, class_name: "CommitmentRevision"
has_many :feed_items
```

New callbacks:
- `after_update :track_status_change` -- creates a `CommitmentStatusChange` when `status` changes
- `after_update :snapshot_revision` -- creates a `CommitmentRevision` when `title`, `description`, `original_text`, or `target_date` changes

New class method:
- `Commitment.search(query)` -- PostgreSQL full-text search using `plainto_tsquery`

New instance methods:
- `commitment.announcements` -- events where `action_type: :announcement`, ordered by `occurred_at` desc
- `commitment.actions` -- events where `action_type: :concrete_action`, ordered by `occurred_at` desc

#### `CriterionAssessment`

Added `after_create :create_feed_item` callback. Every new assessment automatically appears in the activity feed.

#### `PolicyArea`

Added `has_many :feed_items` association and `scope :ordered` (sorts by `position` then `name`).

---

## API Endpoints

### Home Page

#### Burndown Chart

```
GET /api/burndown/:government_id
```

Returns time-series data for rendering the burndown chart.

**Parameters:**
| Param | Type | Default | Description |
|---|---|---|---|
| `start_date` | date | Earliest commitment `created_at` | Start of date range |
| `end_date` | date | Today | End of date range |

**Response:**

```json
{
  "government": { "id": 1, "name": "45th Canadian Government" },
  "total_commitments": 142,
  "current_status_counts": {
    "not_started": 98,
    "in_progress": 30,
    "partially_implemented": 8,
    "implemented": 4,
    "abandoned": 2
  },
  "commitments_added_by_date": {
    "2025-08-05": 120,
    "2025-09-15": 22
  },
  "status_changes": [
    {
      "commitment_id": 42,
      "previous_status": "not_started",
      "new_status": "in_progress",
      "changed_at": "2025-10-01T14:30:00Z"
    }
  ],
  "date_range": { "start_date": "2025-08-05", "end_date": "2026-03-06" }
}
```

The frontend reconstructs the burndown by:
1. Starting with `commitments_added_by_date` to establish the initial workload curve
2. Replaying `status_changes` chronologically to compute status counts at each point in time
3. Increases in `commitments_added_by_date` show as bumps upward in the burndown

#### At a Glance Grid

```
GET /api/dashboard/:government_id/at_a_glance
```

Returns all commitments grouped by policy area with status counts per area. No parameters.

**Response:**

```json
{
  "government": { "id": 1, "name": "45th Canadian Government" },
  "total_commitments": 142,
  "policy_areas": [
    {
      "id": 3,
      "name": "Defence and Security",
      "slug": "defence-and-security",
      "position": 1,
      "status_counts": { "not_started": 8, "in_progress": 3 },
      "commitments": [
        {
          "id": 42,
          "title": "Increase defence spending to 2% of GDP",
          "status": "in_progress",
          "commitment_type": "spending",
          "lead_department": "Department of National Defence"
        }
      ]
    },
    {
      "id": null,
      "name": "Unassigned",
      "slug": "unassigned",
      "position": 999,
      "status_counts": { "not_started": 2 },
      "commitments": [...]
    }
  ]
}
```

Policy areas are ordered by `position` (set in Avo admin), then alphabetically by `name`. Commitments without a policy area appear in an "Unassigned" bucket at the end.

---

### Explore Tab

#### List / Search / Filter Commitments

```
GET /commitments
```

**Parameters:**

| Param | Type | Description |
|---|---|---|
| `q` | string | Full-text search on title + description |
| `policy_area_id` | integer | Filter by policy area |
| `status` | string | Filter by status (e.g., `not_started`, `in_progress`) |
| `commitment_type` | string | Filter by type (e.g., `legislative`, `spending`) |
| `department_id` | integer | Filter by responsible department |
| `party_code` | string | Filter by party |
| `region_code` | string | Filter by region |
| `sort` | string | Sort field: `title`, `date_promised`, `last_assessed_at`, `status` |
| `direction` | string | `asc` or `desc` (default: `desc`) |
| `page` | integer | Page number (default: 1) |
| `per_page` | integer | Results per page (default: 50, max: 100) |

**Response:**

```json
{
  "commitments": [
    {
      "id": 42,
      "title": "Increase defence spending to 2% of GDP",
      "description": "...",
      "commitment_type": "spending",
      "status": "in_progress",
      "date_promised": "2025-04-28",
      "target_date": "2030-12-31",
      "region_code": "CA",
      "party_code": "LPC",
      "policy_area": { "id": 3, "name": "Defence and Security", "slug": "defence-and-security" },
      "lead_department": { "id": 7, "display_name": "National Defence" }
    }
  ],
  "meta": {
    "total_count": 142,
    "page": 1,
    "per_page": 50
  }
}
```

Full-text search uses PostgreSQL `to_tsvector` / `plainto_tsquery` with English stemming. Searching "defence spending" matches commitments containing either word in title or description.

---

### Commitment Detail

```
GET /commitments/:id
```

Returns the full commitment with all nested data. The response includes everything from the original endpoint plus these new sections:

#### `timeline`

All events for this commitment, ordered chronologically.

```json
{
  "timeline": [
    {
      "id": 1,
      "event_type": "promised",
      "action_type": "announcement",
      "title": "Commitment made in Liberal Platform 2025",
      "description": "...",
      "occurred_at": "2025-04-28",
      "source": { "id": 5, "title": "Liberal Platform 2025", "source_type": "platform_document" }
    },
    {
      "id": 2,
      "event_type": "legislative_action",
      "action_type": "concrete_action",
      "title": "Bill C-42 introduced",
      "description": "...",
      "occurred_at": "2025-11-15",
      "source": null
    }
  ]
}
```

#### `announcements` and `actions`

The same events as `timeline`, but pre-filtered by `action_type`. These power the "talk vs. changed" view.

- `announcements` -- events where `action_type` is `announcement` (speeches, press conferences, debate mentions)
- `actions` -- events where `action_type` is `concrete_action` (bills, OICs, budget allocations, regulations)

Both arrays have the same shape as individual `timeline` entries (minus `event_type` and `action_type`).

#### `revisions`

Drift history, ordered by `revision_date`. Each entry captures what the commitment looked like at a previous point in time.

```json
{
  "revisions": [
    {
      "id": 1,
      "title": "Original title before change",
      "description": "Original description...",
      "original_text": "...",
      "target_date": "2028-12-31",
      "change_summary": "Target date pushed from 2028 to 2030",
      "revision_date": "2026-01-15",
      "source": { "id": 10, "title": "Budget 2026", "source_type": "budget" }
    }
  ]
}
```

Revisions are created automatically when `title`, `description`, `original_text`, or `target_date` changes on a commitment. The revision stores the **previous** values. Comparing consecutive revisions shows how the commitment drifted.

The `change_summary` field is intended to be populated by the assessment pipeline or manually -- it is not auto-generated.

#### `status_history`

Chronological record of every status change.

```json
{
  "status_history": [
    {
      "id": 1,
      "previous_status": "not_started",
      "new_status": "in_progress",
      "changed_at": "2025-10-01T14:30:00.000Z",
      "reason": "Bill C-42 introduced in Parliament"
    }
  ]
}
```

#### `recent_feed`

The 20 most recent feed items for this commitment.

```json
{
  "recent_feed": [
    {
      "id": 5,
      "event_type": "status_change",
      "title": "Commitment status changed to in_progress",
      "summary": "Bill C-42 introduced in Parliament",
      "occurred_at": "2025-10-01T14:30:00.000Z"
    }
  ]
}
```

---

### Activity Feed

#### Global Feed

```
GET /feed
GET /feed.rss
```

#### Per-Commitment Feed

```
GET /commitments/:commitment_id/feed
GET /commitments/:commitment_id/feed.rss
```

Both endpoints support the same parameters and return the same shape. The per-commitment route scopes results to a single commitment.

**Parameters:**

| Param | Type | Description |
|---|---|---|
| `event_type` | string | Filter: `status_change`, `event`, `drift`, `criterion_assessed` |
| `policy_area_id` | integer | Filter by policy area |
| `since` | datetime | Only items after this date |
| `until` | datetime | Only items before this date |
| `page` | integer | Page number (default: 1) |
| `per_page` | integer | Results per page (default: 50, max: 100) |

**JSON response:**

```json
{
  "feed_items": [
    {
      "id": 5,
      "event_type": "status_change",
      "title": "Commitment status changed to in_progress",
      "summary": "Bill C-42 introduced",
      "occurred_at": "2025-10-01T14:30:00Z",
      "commitment": { "id": 42, "title": "Increase defence spending to 2% of GDP" },
      "policy_area": { "id": 3, "name": "Defence and Security" }
    }
  ],
  "meta": { "page": 1, "per_page": 50 }
}
```

**RSS response** (when requesting `.rss` format):

Standard RSS 2.0 XML. Each feed item becomes an `<item>` with `<title>`, `<description>`, `<pubDate>`, `<guid>`, and `<category>` (set to the `event_type`). All filters work on RSS feeds too, so users can subscribe to filtered feeds (e.g., `/feed.rss?policy_area_id=3&event_type=status_change`).

---

## How Feed Items Are Created

Feed items are never created directly by API consumers. They are produced by `after_create` callbacks on the source models:

| Source Model | Trigger | Feed `event_type` |
|---|---|---|
| `CommitmentStatusChange` | Commitment status changes | `status_change` |
| `CommitmentEvent` | Event created (by pipeline or manually) | `event` |
| `CommitmentRevision` | Commitment title/description/text/target_date edited | `drift` |
| `CriterionAssessment` | Criterion status assessed | `criterion_assessed` |

The callback chain works like this:

```
Commitment.update!(status: :in_progress)
  -> after_update :track_status_change
    -> CommitmentStatusChange.create!(...)
      -> after_create :create_feed_item
        -> FeedItem.create!(event_type: "status_change", ...)
```

All of this happens inside the same database transaction, so either everything commits or nothing does.

---

## Files

### New Files

| File | Purpose |
|---|---|
| `db/migrate/20260306000001_create_commitment_status_changes.rb` | Status change audit table |
| `db/migrate/20260306000002_create_commitment_events.rb` | Timeline events table |
| `db/migrate/20260306000003_create_commitment_revisions.rb` | Drift snapshots table |
| `db/migrate/20260306000004_create_feed_items.rb` | Unified feed table |
| `db/migrate/20260306000005_add_position_to_policy_areas.rb` | Display ordering |
| `db/migrate/20260306000006_add_search_index_to_commitments.rb` | Full-text search GIN index |
| `app/models/commitment_status_change.rb` | Model with feed item callback |
| `app/models/commitment_event.rb` | Model with event_type + action_type enums |
| `app/models/commitment_revision.rb` | Model with feed item callback |
| `app/models/feed_item.rb` | Polymorphic model with filter scopes |
| `app/controllers/api/burndown_controller.rb` | Burndown chart data |
| `app/controllers/api/dashboard_controller.rb` | At-a-glance grid data |
| `app/controllers/feed_items_controller.rb` | Feed JSON + RSS |
| `app/views/commitments/index.json.jbuilder` | Paginated commitment list |

### Modified Files

| File | Changes |
|---|---|
| `app/models/commitment.rb` | Added associations, callbacks, `.search()`, `announcements`/`actions` |
| `app/models/criterion_assessment.rb` | Added `after_create` feed item callback |
| `app/models/policy_area.rb` | Added `feed_items` association, `ordered` scope |
| `app/controllers/commitments_controller.rb` | Search, filters, sorting, pagination |
| `app/views/commitments/show.json.jbuilder` | Added timeline, announcements, actions, revisions, status_history, recent_feed |
| `config/routes.rb` | Added feed, burndown, dashboard routes |
