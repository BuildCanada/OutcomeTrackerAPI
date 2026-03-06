# Commitments

## Purpose

Commitments are the structured, trackable representation of government promises. They solve three problems:

1. **Typed classification** -- A legislative promise (pass a bill) has completely different verification needs than a spending promise (allocate $X) or a diplomatic one (negotiate a treaty). Commitments classify each one so the verification pipeline can apply the right logic.

2. **Structured criteria** -- Instead of a single score and text summary, commitments break assessment into explicit, assessable criteria (success, execution, and progress).

3. **Scoped matching** -- Commitments have typed classification and department ownership so evidence matching can be scoped and precise.

## Data Model

### Commitment

The core record. Every commitment belongs to a `Government` and has a `commitment_type` and `status`.

**Required fields:**
- `title` -- Clean, concise title (e.g., "Increase defence spending to 2% of GDP")
- `description` -- Precise description of what was promised
- `commitment_type` -- What kind of promise this is (see below)
- `government_id` -- Which government made this commitment

**Optional fields:**
- `parent_id` -- Self-referencing FK for decomposing compound promises into children
- `original_text` -- Verbatim source text from the platform/speech/document
- `policy_area_id` -- FK to `policy_areas` table (defence, healthcare, housing, etc.)
- `date_promised` -- When the commitment was first made
- `target_date` -- When it's supposed to be fulfilled
- `last_assessed_at` -- When progress was last evaluated
- `region_code` / `party_code` -- For filtering
- `superseded_by_id` -- Self-referencing FK to the replacement commitment (set when status is `superseded`)
- `metadata` -- JSONB for flexible LLM enrichment data

### Commitment Types

Each type implies different verification approaches:

| Type | What it means | Verification looks like |
|---|---|---|
| `legislative` | Pass a law, amend legislation, create regulation | Track bills through Parliament, check gazette |
| `spending` | Allocate money, increase/decrease funding | Budget documents, estimates, public accounts |
| `procedural` | Change how government operates (process, timeline, reporting) | OICs, directives, TB submissions |
| `institutional` | Create/restructure an agency, board, or office | Machinery of government changes, GIC appointments |
| `diplomatic` | International agreements, treaties, alliances | Treaty actions, joint statements, ratifications |
| `outcome` | Measurable outcome goals with specific targets ("reduce poverty by 50%") | StatCan indicators, departmental results reports, published metrics |
| `aspirational` | Non-measurable goals without specific targets or mechanisms ("strengthen the middle class") | Subjective assessment, directional indicators |

### Statuses

| Status | Meaning |
|---|---|
| `not_started` | No observable action taken (default) |
| `in_progress` | Government has begun work but not completed |
| `partially_implemented` | Some elements delivered, others outstanding |
| `implemented` | Commitment fulfilled as described |
| `abandoned` | Government explicitly or implicitly dropped this |
| `superseded` | Replaced by a different commitment (linked via `superseded_by_id`) |

## Criteria

Criteria define what to look for when assessing a commitment. They live in a single `criteria` table with a `category` enum that scopes them into three types.

Not every commitment needs all three categories. A simple spending commitment might only need success criteria. A complex legislative one might use all three.

### Success Criteria

**"What does done look like?"**

These define the end state. If all success criteria are met, the commitment is implemented.

Example for "Increase defence spending to 2% of GDP":
- Defence spending reaches 2% of GDP as reported by NATO
- Spending level sustained for at least one fiscal year

### Execution Criteria

**"What steps should we see along the way?"**

These are the observable government actions that indicate work is happening. They help distinguish "in progress" from "not started."

Example:
- Annual budget allocations show year-over-year increase in defence spending
- DND receives increased Main Estimates allocation
- Procurement contracts awarded for major equipment

### Progress Criteria

**"What intermediate outcomes indicate movement?"**

These are measurable indicators that track partial progress, useful for commitments that take years to fulfill.

Example:
- Defence spending as % of GDP increases from baseline (1.3%)
- Capital spending ratio increases within DND budget
- Personnel strength targets met for CAF expansion

### Criterion Fields

Each criterion has:
- `description` -- What specifically to look for
- `verification_method` -- How to check it (data source, URL to monitor, etc.)
- `status` -- `not_assessed`, `met`, `partially_met`, `not_met`, `no_longer_applicable` (current/latest state)
- `evidence_notes` -- Why the current status was set
- `assessed_at` -- When it was last assessed
- `position` -- Display ordering within its category

All assessments are LLM-driven. The criterion table holds the current state; the full history is in `criterion_assessments`.

### Criterion Assessments (Audit Trail)

Every time a criterion's status changes, a `CriterionAssessment` record is created to capture the transition:

- `criterion_id` -- Which criterion changed
- `previous_status` -- Status before the change
- `new_status` -- Status after the change
- `source_id` -- FK to the `Source` document that triggered the change (optional)
- `evidence_notes` -- Explanation of why the status changed
- `assessed_at` -- When the assessment was made

This provides a complete audit trail of how each criterion was evaluated over time, including which source documents drove each status change.

## Sources

Sources use a two-model architecture:

### `Source` (the document)

A `Source` represents a specific document or event that can be referenced by many commitments. Each source belongs to a `Government` and has:

- `title` -- e.g., "Liberal Platform 2025", "Budget 2025"
- `source_type` -- Classification of the document type (see below)
- `url` -- Link to the document (optional)
- `date` -- Publication date (optional)

| Source Type | Example |
|---|---|
| `platform_document` | Party election platform |
| `speech_from_throne` | Speech from the Throne |
| `budget` | Federal budget document |
| `press_conference` | PM or minister announcement |
| `mandate_letter` | Ministerial mandate letter |
| `debate` | Parliamentary debate (Hansard) |
| `order_in_council` | Order in Council (OIC/GIC) |
| `treasury_board_submission` | Treasury Board submission or decision |
| `gazette_notice` | Canada Gazette notice |
| `committee_report` | Parliamentary committee report |
| `departmental_results_report` | Departmental results or performance report |
| `other` | Anything else (requires `source_type_other` to be filled in) |

When `source_type` is `other`, the `source_type_other` field must be populated with a description of the document type.

### `CommitmentSource` (the join)

A `CommitmentSource` links a commitment to a source with optional context:

- `source_id` -- The referenced source document
- `commitment_id` -- The linked commitment
- `section` -- Section within the source (e.g., "Chapter 3: Defence")
- `reference` -- Page or clause reference (e.g., "p. 42")
- `excerpt` -- The relevant passage from the source

A single source can be referenced by many commitments, and a single commitment can reference many sources.

## Policy Areas

Commitments are classified into policy areas via the `policy_areas` reference table. Each policy area has a `name`, `slug`, and optional `description`.

Policy areas are managed through the Avo admin and seeded via `db/seeds/policy_areas.rb`. New policy areas can be added at any time without code changes.

Access patterns:
- `commitment.policy_area` -- The policy area for this commitment
- `policy_area.commitments` -- All commitments in a policy area

## Department Ownership

Commitments are linked to departments via the `commitment_departments` join table, mirroring the existing `department_promises` pattern. One department can be flagged as `is_lead: true`.

Access patterns on the Commitment model:
- `commitment.departments` -- All responsible departments
- `commitment.lead_department` -- The primary department
- `commitment.commitment_departments` -- Join records (includes `is_lead` flag)

## Parent-Child Decomposition

Compound promises should be broken into atomic commitments using the `parent_id` self-referencing FK.

Example:
```
Parent: "Strengthen Canada's defence and security"
  Child: "Increase defence spending to 2% of GDP"
  Child: "Procure new fighter jets for the RCAF"
  Child: "Expand Canadian Armed Forces by 15,000 personnel"
```

Each child gets its own type, criteria, and assessment. The parent serves as an organizational grouping. Progress on the parent can be derived from its children.

Access patterns:
- `commitment.children` -- All child commitments
- `commitment.parent` -- The parent commitment (nil if top-level)

## API

Read-only JSON API at:
- `GET /commitments` -- List all commitments
- `GET /commitments/:id` -- Full commitment detail including nested sources, criteria, departments, children, and parent

## Admin

All models (Commitment, Source, CommitmentSource, Criterion, CriterionAssessment, CommitmentDepartment, PolicyArea) are available in the Avo admin at `/admin`. Commitments can be created, edited, and managed entirely through the admin UI.

## Structuring Guidelines

When creating commitments:

1. **One verifiable thing per commitment.** If a platform bullet contains multiple distinct promises, decompose it into parent + children.

2. **Title should be specific and action-oriented.** "Increase defence spending to 2% of GDP" not "Strengthen defence."

3. **Description should be precise enough to verify.** Include the specific target, timeline, or mechanism if stated in the source.

4. **Always set commitment_type.** This determines how the future evidence pipeline will assess it.

5. **Include at least one success criterion.** Without it, there's no definition of "done."

6. **Preserve original text.** Copy the verbatim source passage into `original_text` so there's a record of exactly what was said.

7. **Link sources.** Every commitment should have at least one source documenting where it came from.

8. **Assign a lead department.** Even if multiple departments are involved, one should own it.
