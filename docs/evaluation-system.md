# Evaluation System Overview

The Build Canada Tracker monitors 603 federal government commitments from the Liberal platform, Budget 2025, and Speech from the Throne. It evaluates whether the government is fulfilling its promises using four independent evaluation layers — each measuring a different dimension of accountability.

---

## Layer 1: Commitment Status

Tracks whether the government has acted on each commitment.

| Status | Meaning |
|--------|---------|
| `not_started` | No evidence of action taken |
| `in_progress` | Concrete steps underway but not yet fulfilled |
| `completed` | Government did what it said it would do |
| `abandoned` | Explicitly reversed or dropped |

### Evidence Hierarchy

Status is derived by AI analysis against a strict evidence hierarchy:

**"Completed" requires one of:**
- Matched bill with Royal Assent
- Canada Gazette Part II/III entry (enacted regulation)
- Departmental news confirming an operational program

**"In progress" requires one of:**
- Bill introduced and progressing in Parliament (no Royal Assent yet)
- Canada Gazette Part I entry (proposed regulation)
- Appropriation voted with program implementation evidence

**Budget announcements alone are never sufficient.** A budget promise without a bill, regulation, or program launch remains `not_started`.

> Source: `OutcomeTrackerAPI/app/models/commitment_status_deriver.rb`

---

## Layer 2: Criteria Assessment

Each commitment is broken into ~10-12 measurable criteria across four categories:

| Category | Question It Answers | Example |
|----------|---------------------|---------|
| **Completion** | Did the government literally do what it said? ("the letter") | Bill received Royal Assent; funds allocated and disbursed |
| **Success** | Did the real-world outcome materialize? ("the spirit") | Housing starts actually reached 500K/year |
| **Progress** | Are they actively working toward it? | Bill introduced; consultations launched |
| **Failure** | Has the commitment been broken or contradicted? | Bill withdrawn; funds cut; policy reversed |

### Criterion Statuses

| Status | Meaning |
|--------|---------|
| `not_assessed` | Not yet evaluated |
| `met` | Criterion satisfied with evidence |
| `not_met` | Criterion not satisfied |
| `no_longer_applicable` | Conditions changed; criterion is moot |

Each criterion includes a **measurable description**, a **verification method** naming the exact source (LEGISinfo bill number, StatCan table ID, Gazette reference, Budget chapter), and **evidence notes** with citations.

The completion/success split is the core design insight: a government can pass legislation (completion = met) while the intended outcome never materializes (success = not met), or vice versa.

> Source: `OutcomeTrackerAPI/docs/commitment_evaluation_plan.md`

---

## Layer 3: Commitment Quality Grading

Evaluates the quality of how each commitment was defined, not whether it was delivered. Scored across six dimensions:

| Dimension | What It Measures | A (5) | F (1) |
|-----------|------------------|-------|-------|
| **Title Quality** | Concise, specific, ≤80 chars | Includes $ or deadline | Vague umbrella language |
| **Description Quality** | Detail, measurability, specifics | Has $ amounts AND numbers | <10 words, no specifics |
| **Measurability** | Can the outcome be objectively verified? | 3+ measurable indicators | No measurable outcome |
| **Specificity** | Concrete actions vs. aspirational language | $ figures or 2+ targets | Vague umbrella language |
| **Type Accuracy** | Classification matches content | No conflicts | Spending tagged as procedural |
| **Policy Area Fit** | Categorized in the right area | Content matches area | Housing commitment in "Foreign Affairs" |

**Overall grade** = average of six scores: **A** ≥ 4.0 | **B** ≥ 3.5 | **C** ≥ 2.5 | **D** ≥ 1.5 | **F** < 1.5

Results stored in `evals.sqlite3`.

> Source: `build_evals.py`

---

## Layer 4: Build Canada Relevance Ranking

Measures how each commitment aligns with Build Canada's economic tenets.

### Scoring Dimensions

| Dimension | Scale | Anchors |
|-----------|-------|---------|
| **Relevance (R)** | 1–5 | 1 = touches no tenets → 5 = directly advances 3+ tenets |
| **Scale (S)** | 1–5 | 1 = <C$0.1B impact or local only → 5 = ≥C$10B impact or >0.5pp GDP change |
| **Direction** | categorical | `positive` (advances tenets), `negative` (undermines tenets), `neutral` |

### Overall Rank

| Rank | Rule |
|------|------|
| **Strong** | R ≥ 4 **and** S ≥ 4 |
| **Medium** | (R + S) ≥ 6 |
| **Weak** | Everything else |

Each ranking includes a rationale (<40 words) anchored to the commitment text and tenets.

> Source: `OutcomeTracker/prompts/detailed_rating_instructions.md`

---

## How the Layers Connect

```
                    ┌─────────────────────────────┐
                    │     EVIDENCE SOURCES         │
                    │  LEGISinfo · Gazette · StatCan│
                    │  Departmental news · Budget   │
                    └──────────────┬──────────────┘
                                   │
                                   ▼
                    ┌─────────────────────────────┐
                    │   CRITERIA ASSESSMENT (L2)   │
                    │  Each criterion scored as     │
                    │  met / not_met / not_assessed  │
                    └──────────────┬──────────────┘
                                   │
                                   ▼
                    ┌─────────────────────────────┐
                    │  COMMITMENT STATUS (L1)       │
                    │  AI derives status from       │
                    │  criteria + evidence hierarchy │
                    └──────────────┬──────────────┘
                                   │
              ┌────────────────────┼────────────────────┐
              ▼                                         ▼
┌──────────────────────┐              ┌──────────────────────┐
│  QUALITY GRADE (L3)  │              │  BC RELEVANCE (L4)   │
│  How well-defined    │              │  How aligned with    │
│  is the commitment?  │              │  Build Canada tenets │
└──────────────────────┘              └──────────────────────┘
```

- **L1 + L2** answer: *Is the government doing what it promised, and is it working?*
- **L3** answers: *Was the promise well-defined enough to track?*
- **L4** answers: *Does this commitment matter for Canada's economic future?*
