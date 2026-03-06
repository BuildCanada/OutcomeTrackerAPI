# Commitment Evaluation Pipeline Plan

## Overview

A two-tier LLM pipeline that evaluates government commitments against incoming data from feeds, parliamentary bills, and Statistics Canada datasets.

- **Small model** (`gemini-3.1-flash-lite-preview`): Fast relevance filtering -- determines if incoming data relates to each commitment
- **Big model** (`gemini-3.1-pro-preview`): Deep assessment -- generates evaluation criteria and assesses criterion status

Models are configurable per Chat subclass so they can be swapped without code changes.

---

## 1. Data Sufficiency Assessment

### Current Sources vs. Commitment Types

| Commitment Type | Current Sources | Coverage | Key Gaps |
|---|---|---|---|
| `legislative` | Bills API (parl.ca), Canada Gazette feeds, Hansard feeds | **Strong** | Committee testimony, regulatory impact analysis |
| `spending` | News feeds (budget announcements) | **Weak** | No direct budget API; no Main Estimates/Supplementary Estimates/Public Accounts feeds |
| `procedural` | Canada Gazette (OICs, directives) | **Medium** | Treasury Board decisions not typically public |
| `institutional` | Gazette notices, news feeds | **Medium** | No GIC appointments feed, no PCO organizational changes feed |
| `diplomatic` | News feeds | **Weak** | No treaty database API; no GAC-specific feeds |
| `outcome` | StatCan datasets | **Medium** | Need commitment-specific StatCan table mappings; no departmental results report feeds |
| `aspirational` | All sources (directional) | **Low by nature** | Inherently subjective; best covered by expert assessment + directional indicators |

### Verdict

The existing sources provide **good coverage for legislative commitments** and **partial coverage for procedural/institutional/outcome types**. The biggest gaps are:
1. **Spending verification** -- no structured budget/estimates data
2. **Diplomatic tracking** -- no treaty or international agreement feeds
3. **StatCan-to-commitment mapping** -- the infrastructure exists but specific datasets aren't mapped to commitments

---

## 2. New Data Model: `CommitmentMatch`

The central new model. Records "this piece of incoming data is relevant to this commitment" regardless of data source type.

### Table: `commitment_matches`

| Column | Type | Notes |
|---|---|---|
| `commitment_id` | bigint FK NOT NULL | References `commitments` |
| `matchable_type` | string NOT NULL | Polymorphic: `Entry`, `Bill`, `StatcanDataset` |
| `matchable_id` | bigint NOT NULL | Polymorphic ID |
| `relevance_score` | float NOT NULL | 0.0-1.0 from small model |
| `relevance_reasoning` | text | Short explanation from small model |
| `matched_at` | datetime NOT NULL | When the match was made |
| `assessed` | boolean DEFAULT false | Whether big model has processed this match |
| `assessed_at` | datetime | When big model assessed it |
| `metadata` | jsonb DEFAULT {} | Additional context |

**Indexes:**
- `[commitment_id, matchable_type, matchable_id]` UNIQUE
- `[matchable_type, matchable_id]`
- `[commitment_id, assessed]`

### Why Polymorphic

All three data sources (entries, bills, statcan) need the same relationship. A polymorphic join avoids three identical tables and lets the relevance filtering job work generically.

### Why Not Extend Evidence

The existing `Evidence` model is tightly coupled to `Promise` + `Activity` with impact/magnitude fields that don't map to criterion-based assessment. A clean new model avoids polluting either system.

### Additional Tracking Columns

- `entries.last_commitment_matched_at` -- track which entries have been filtered
- `bills.last_commitment_matched_at` -- track which bills have been filtered

---

## 3. LLM Chat Classes

All follow the existing pattern: inherit from `Chat`, include `Structify::Model`, define `schema_definition`.

### 3A. `CommitmentRelevanceFilter` (Small Model)

**Model:** `gemini-3.1-flash-lite-preview`

Takes all active commitment summaries + one data item. Returns which commitments are relevant. This mirrors the existing `ActivityExtractor` pattern that passes `Promise.all`.

**Design choice:** Batch commitments per data item (not the reverse). With ~100-200 commitments and ~50 entries per cycle, this means ~50 LLM calls per cycle instead of 5,000+.

**Schema:**

```ruby
schema_definition do
  version 1
  name "CommitmentRelevanceFilter"
  description "Filters incoming data for relevance to commitments"
  field :matches, :array,
    description: "Commitments this data item is relevant to. Return empty array if none.",
    items: {
      type: "object", properties: {
        "commitment_id" => { type: "integer" },
        "relevance_score" => { type: "number", description: "0.0-1.0" },
        "relevance_reasoning" => { type: "string", description: "1-2 sentences" }
      }
    }
end
```

**Three prompt methods** (one per data source type):
- `prompt_for_entry(commitments, entry)` -- uses existing `entry.format_for_llm`
- `prompt_for_bill(commitments, bill)` -- formats bill title, stages, latest activity
- `prompt_for_statcan(commitments, dataset)` -- formats dataset name + data summary

**Threshold:** Only create `CommitmentMatch` records where `relevance_score >= 0.5`.

### 3B. `CriteriaGenerator` (Big Model)

**Model:** `gemini-3.1-pro-preview`

For commitments without criteria. Takes full commitment context and generates appropriate criteria based on commitment type.

**Criteria categories:**
- **Completion** — Did they literally do what they said? The letter of the commitment.
- **Success** — Did the real-world outcome materialize as intended? The spirit of the commitment. After the government acted on paper, did the intended effect actually happen?
- **Progress** — Are they actively working towards it? Evidence of steps being taken toward fulfillment.
- **Failure** — Is the commitment broken or actively contradicted? Red flags that indicate abandonment, reversal, or undermining — not just absence of progress, but evidence of active contradiction.

**Schema:**

```ruby
schema_definition do
  version 1
  name "CriteriaGenerator"
  description "Generates assessment criteria for a commitment"
  field :criteria, :array,
    items: {
      type: "object", properties: {
        "category" => { type: "string", enum: ["completion", "success", "progress", "failure"] },
        "description" => { type: "string" },
        "verification_method" => { type: "string" },
        "position" => { type: "integer" }
      }
    }
end
```

The prompt includes commitment type-specific guidance (e.g., legislative commitments should have criteria about bill stages; spending commitments about budget allocations).

### 3C. `CriterionAssessor` (Big Model)

**Model:** `gemini-3.1-pro-preview`

Takes one criterion + all matched evidence for its commitment. Determines criterion status.

**Schema:**

```ruby
schema_definition do
  version 1
  name "CriterionAssessor"
  description "Assesses a criterion against matched evidence"
  field :assessment, :object, properties: {
    "new_status" => { type: "string", enum: ["not_assessed", "met", "partially_met", "not_met", "no_longer_applicable"] },
    "evidence_notes" => { type: "string" },
    "confidence" => { type: "number", description: "0.0-1.0" }
  }
end
```

Only creates a `CriterionAssessment` audit record when status actually changes.

---

## 4. Job Architecture

### New Jobs

| Job | Trigger | Model | Purpose |
|---|---|---|---|
| `CommitmentRelevanceFilterJob` | After entry activity extraction, after bill sync, after statcan sync | Small | Match data to commitments |
| `CriteriaGeneratorJob` | On demand / backfill | Big | Generate criteria for commitments that lack them |
| `CommitmentAssessmentJob` | Per-commitment | Big | Assess all criteria for one commitment |
| `CommitmentAssessmentCronJob` | Every 6 hours (cron) | N/A | Orchestrator: finds commitments with unassessed matches, enqueues assessment jobs |

### Integration Points

**Entries** -- Hook into `Entry#fetch_data!` after the existing `extract_activities!` call:

```
Entry#fetch_data!
  -> EntryDataFetcherJob (existing)
    -> Entry#extract_activities! (existing, for Promise pipeline)
    -> Entry#filter_commitment_relevance! (NEW)
      -> CommitmentRelevanceFilterJob
```

**Bills** -- After `Bill.sync_all`, filter bills with new activity:

```
BillsCronJob (existing)
  -> Bill.sync_all (existing)
  -> For each bill where latest_activity_at > last_commitment_matched_at:
    -> CommitmentRelevanceFilterJob
```

**StatCan** -- After `StatcanDataset#sync!`:

```
StatcanSyncJob (existing)
  -> StatcanDataset#sync! (existing)
  -> CommitmentRelevanceFilterJob (NEW)
```

**Assessment** -- Periodic orchestrator:

```
CommitmentAssessmentCronJob (every 6h)
  -> Find commitments with unassessed high-relevance matches
  -> For each: CommitmentAssessmentJob
    -> If no criteria: CriteriaGeneratorJob (inline)
    -> For each criterion: CriterionAssessor
      -> Create CriterionAssessment if status changed
    -> Derive Commitment#status from criteria roll-up
    -> Update Commitment#last_assessed_at
```

### Why 6 Hours for Assessment

The 3-hour data ingestion cycle means evidence accumulates between assessment runs. Batching reduces duplicate LLM calls when multiple entries arrive about the same topic. Max latency from data ingestion to assessment: ~9 hours, acceptable for government accountability tracking.

### GoodJob Cron Addition

```ruby
commitment_assessment: {
  cron: "0 */6 * * *",
  class: "CommitmentAssessmentCronJob",
  description: "Assess commitments with new evidence matches",
  enabled_by_default: -> { Rails.env.production? }
}
```

---

## 5. Commitment Status Derivation

After criteria are assessed, derive the commitment's overall status:

```
Any failure criteria met                     -> :abandoned (actively broken or contradicted)
All completion + all success criteria met    -> :implemented (did it AND it worked)
All completion criteria met                 -> :partially_implemented (did it on paper, but real-world outcome TBD or incomplete)
Any progress criteria met                   -> :in_progress (actively working towards it)
No criteria met                             -> :not_started (no change)
```

`:abandoned` and `:superseded` are never derived -- they require explicit human setting.

---

## 6. Backfill Strategy

### Phase 1: Generate Criteria

For all existing commitments that lack criteria:

```ruby
Commitment.left_joins(:criteria).where(criteria: { id: nil }).find_each do |c|
  CriteriaGeneratorJob.perform_later(c)
end
```

### Phase 2: Backfill from Existing Entries

Run relevance filtering against all processed entries (those with `activities_extracted_at` set and not skipped):

```ruby
Entry.where.not(activities_extracted_at: nil)
     .where(skipped_at: nil)
     .find_each do |entry|
  CommitmentRelevanceFilterJob.perform_later(entry)
end
```

This captures all historical scraped data without needing to bridge through the Promise/Evidence models.

### Phase 3: Backfill from Bills

```ruby
Bill.find_each do |bill|
  CommitmentRelevanceFilterJob.perform_later(bill)
end
```

### Phase 4: Backfill from StatCan

```ruby
StatcanDataset.where.not(current_data: nil).find_each do |ds|
  CommitmentRelevanceFilterJob.perform_later(ds)
end
```

### Phase 5: Run Initial Assessment

After matches are created:

```ruby
Commitment.joins(:commitment_matches)
  .where(commitment_matches: { assessed: false })
  .distinct.find_each do |c|
  CommitmentAssessmentJob.perform_later(c)
end
```

### Rake Task

All phases wrapped in `lib/tasks/commitment_backfill.rake` with individual tasks per phase and a `backfill:all` umbrella task.

---

## 7. Additional Data Sources (Priority Ordered)

### Priority 1 -- High Impact, Feasible Now

| Source | URL/Feed | Commitment Types | Status |
|---|---|---|---|
| Orders in Council RSS | `orders-in-council.canada.ca` | procedural, institutional | **Skipped** -- no RSS feed available |
| Budget/Fiscal documents | `fin.gc.ca` press releases RSS | spending | **Done** -- already existed as Department of Finance feed |
| PM press releases | `pm.gc.ca/en/rss.xml` | all types | **Done** |
| Departmental newsrooms | `canada.ca/en/news` per department | all types | **Done** -- DND, IRCC, ISC, ISED, GAC, Health, Environment, ESDC, Transport, NRCan, TBS, CIRNAC |

### Priority 2 -- Medium Impact

| Source | Commitment Types | Status |
|---|---|---|
| Departmental Results Reports | outcome, spending | Annual publication per department; scraper or manual Source entry |
| GAC Treaty database | diplomatic | `treaty-accord.gc.ca`; may need custom scraper |
| House/Senate Committee feeds | legislative | `parl.ca` committee reports RSS |
| Parliamentary Budget Officer | spending, outcome | **Done** -- `pbo-dpb.ca/en/feed.xml` |

### Priority 3 -- Nice to Have

| Source | Commitment Types | Notes |
|---|---|---|
| Public Accounts of Canada | spending | Annual only; manual Source entry |
| Specific StatCan indicators | outcome | Map GDP, housing starts, immigration, etc. per commitment |
| Main Estimates / Supplementary Estimates | spending | TBS publications; may need PDF extraction |

---

## 8. New Files Summary

| File | Purpose |
|---|---|
| `app/models/commitment_match.rb` | Polymorphic join: data source to commitment |
| `app/models/commitment_relevance_filter.rb` | Small model Chat subclass |
| `app/models/criteria_generator.rb` | Big model Chat subclass |
| `app/models/criterion_assessor.rb` | Big model Chat subclass |
| `app/jobs/commitment_relevance_filter_job.rb` | Job wrapper for relevance filtering |
| `app/jobs/criteria_generator_job.rb` | Job wrapper for criteria generation |
| `app/jobs/commitment_assessment_job.rb` | Job wrapper for per-commitment assessment |
| `app/jobs/commitment_assessment_cron_job.rb` | Periodic orchestrator |
| `db/migrate/..._create_commitment_matches.rb` | New table |
| `db/migrate/..._add_tracking_columns.rb` | `last_commitment_matched_at` on entries + bills |
| `lib/tasks/commitment_backfill.rake` | Backfill rake tasks |

### Modified Files

| File | Change |
|---|---|
| `app/models/commitment.rb` | Add associations, `generate_criteria!`, `assess_criteria!`, `derive_status_from_criteria!` |
| `app/models/entry.rb` | Add `has_many :commitment_matches`, `filter_commitment_relevance!`, hook after activity extraction |
| `app/models/bill.rb` | Add `has_many :commitment_matches`, `filter_commitment_relevance!`, `format_for_llm` |
| `app/models/statcan_dataset.rb` | Add `has_many :commitment_matches`, `filter_commitment_relevance!`, `format_for_llm` |
| `config/initializers/good_job.rb` | Add `commitment_assessment` cron entry |

---

## 9. Implementation Sequence

### Sprint 1: Foundation
1. Migration: `commitment_matches` table + tracking columns
2. `CommitmentMatch` model
3. `CommitmentRelevanceFilter` Chat subclass (entry prompt first)
4. `CommitmentRelevanceFilterJob`
5. Hook into `Entry#fetch_data!`
6. Test: feed refresh -> entry -> commitment matches created

### Sprint 2: Criteria Generation
1. `CriteriaGenerator` Chat subclass
2. `CriteriaGeneratorJob`
3. Backfill criteria for all existing commitments
4. Avo admin visibility for generated criteria

### Sprint 3: Assessment Pipeline
1. `CriterionAssessor` Chat subclass
2. `CommitmentAssessmentJob` + `CommitmentAssessmentCronJob`
3. GoodJob cron config
4. Status derivation logic
5. Test full cycle: entry -> match -> assess -> status update

### Sprint 4: Bills + StatCan
1. `format_for_llm` for `Bill` and `StatcanDataset`
2. Bill relevance filtering (prompt + job hookup after sync)
3. StatCan relevance filtering (prompt + job hookup after sync)

### Sprint 5: Backfill + New Sources
1. Rake tasks for all backfill phases
2. Run backfill: entries, bills, statcan
3. Run initial assessment cycle
4. Add Priority 1 data source feeds

---

## 10. Key Architectural Decisions

**Batch commitments in prompt, not individual matching.** ~100-200 commitments x 50 entries = 50 LLM calls per cycle (one per entry), not 10,000 (one per pair). Mirrors existing `ActivityExtractor` pattern.

**Polymorphic `CommitmentMatch` instead of three join tables.** Same logic for all data sources. One model, one job, one filtering class with type-specific prompts.

**6-hour assessment cycle.** Decouples data ingestion (fast, frequent) from assessment (expensive, batched). Lets evidence accumulate before triggering big-model calls.

**No bridge to Promise/Evidence pipeline.** Commitments use the same raw data (entries, bills, statcan) but through their own relevance filtering. Avoids tight coupling to a system that will eventually be deprecated. Backfill works by re-filtering existing entries, not by migrating Evidence records.

**Source records created during assessment, not filtering.** The relevance filter creates lightweight `CommitmentMatch` records. The big-model assessment step creates proper `Source` + `CommitmentSource` records when it identifies authoritative evidence, maintaining Source as a curated reference table.
