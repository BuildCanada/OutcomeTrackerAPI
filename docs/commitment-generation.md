# Commitment Generation Methodology

## Source Document

**Liberal Platform 2025 — "Canada Strong"**
- 67-page PDF, published April 2025
- Organized into 4 major sections: UNITE, SECURE, PROTECT, BUILD
- Plus Annex 1 (Fiscal Plan) and Annex 2 (GBA+ Analysis)
- Source type: `platform_document`

## Extraction Process

### 1. Text Extraction

The platform PDF was processed using `pdfplumber` to extract full text across all 67 pages. The extracted text was saved to a working file for analysis. Total output: ~161K characters, 2,259 lines.

### 2. Section Identification

The platform uses a consistent structure: narrative context followed by "A Mark Carney-led government will:" blocks containing bulleted commitments. We identified 50+ such blocks across the four major sections.

Line ranges used for extraction:
- **UNITE** (lines 1–272): Internal trade, infrastructure, CBC, Buy Canadian
- **SECURE** (lines 273–763): Defence, veterans, food security, public safety, global leadership
- **PROTECT** (lines 764–1292): Healthcare, families, nature, Indigenous, rights
- **BUILD** (lines 1293–1976): Housing, immigration, energy, AI, trades, fiscal responsibility

### 3. Commitment Decomposition

Each "will:" block was parsed into individual commitments following the structuring guidelines in `docs/commitments.md`:

- **One verifiable thing per commitment.** Compound bullets were decomposed into parent + child commitments where the parent serves as an organizational grouping and each child is independently verifiable.
- **Specific, action-oriented titles.** "Increase defence spending to reach 2% of GDP by 2030" rather than "Strengthen defence."
- **Verbatim text preserved.** The `original_text` field captures the exact wording from the platform for each commitment.

### 4. Classification Decisions

#### Commitment Types

Each commitment was classified based on the nature of the promise:

| Type | Count | Decision Criteria |
|---|---|---|
| `spending` | 115 | Explicit dollar amounts, funding increases, investment programs |
| `procedural` | 85 | Process changes, reviews, strategy launches, agency mandates |
| `legislative` | 40 | Bills, amendments, Criminal Code changes, new Acts |
| `institutional` | 12 | New agencies, offices, boards (e.g., Build Canada Homes, BOREALIS) |
| `outcome` | 20 | Measurable targets (e.g., "100,000 new childcare spaces", "12% Francophone immigration") |
| `diplomatic` | 10 | International agreements, treaties, alliances, foreign aid commitments |
| `aspirational` | 8 | Broad directional goals without specific metrics or mechanisms |

**Key judgment calls:**
- Tax cuts classified as `spending` (they involve fiscal allocation decisions)
- "Launch a review" classified as `procedural` even when the review may lead to legislative action
- Criminal Code amendments classified as `legislative` even when framed as "cracking down on"
- Compound groupings (parent commitments) classified as `aspirational` since they're organizational

#### Policy Areas

Mapped to the 15 seeded policy areas. Key mappings:

- One Canadian Economy / Buy Canadian → `economy`
- Nation-building Projects → `infrastructure`
- Rebuild/Rearm CAF → `defence`
- Food Security / Farmers → `agriculture`
- Gun Control / Safe at Home / Children → `justice`
- Global Leadership → `foreign-affairs`
- Healthcare / Mental Health → `healthcare`
- Families / Seniors / Young Canadians → `social` or `education` (depending on whether education-focused)
- Nature / Clean Investment → `environment`
- Housing sections → `housing`
- Immigration → `immigration`
- Indigenous sections → `indigenous`
- Charter Rights → `democratic-reform`
- Veterans → `veterans`

Some commitments could plausibly map to multiple areas. The primary area was chosen based on the commitment's core mechanism (e.g., a spending commitment that funds Indigenous education was classified under `indigenous` if the primary beneficiary/department is Indigenous Services, or `education` if the mechanism is fundamentally about education policy).

#### Department Assignment

Departments were assigned based on:
1. The platform's own "responsible department" signals where present
2. Standard machinery-of-government responsibilities
3. The nature of the commitment's mechanism

Every commitment has at least one department with `is_lead: true`. Secondary departments were added where implementation clearly requires multi-department coordination.

### 5. Criteria Generation

Each commitment has at minimum one `success` criterion defining what "done" looks like. Many also have `execution` criteria for observable intermediate steps.

**Success criteria** answer: "If we checked in 4 years, what would tell us this was fulfilled?"
- For spending commitments: the funds were allocated and disbursed
- For legislative commitments: the bill received Royal Assent
- For outcome commitments: the measurable target was met
- For institutional commitments: the organization exists and is operational

**Execution criteria** answer: "What government actions should we see along the way?"
- Budget line items, estimates allocations
- Consultations launched, reports published
- Legislation introduced in Parliament
- Procurement contracts awarded

**Verification methods** specify where to look:
- Federal budget documents, Main Estimates
- LEGISinfo for bill tracking
- Canada Gazette for regulations
- Departmental Results Reports
- StatCan indicators
- NATO reports (for defence spending)
- Parliamentary committee proceedings

### 6. Quality Checks

Before generating the final JSONL:
- All `commitment_type` values validated against the enum
- All `policy_area_slug` values validated against seeded slugs
- All `department_slugs` validated against seeded department records
- Every commitment has at least one success criterion
- Every commitment has at least one department assignment
- Parent-child ID references resolved correctly

## Output

- **290 commitments** in `db/seeds/commitments_liberal_2025.jsonl`
- Each line is a self-contained JSON object
- Loaded by `db/seeds/commitments_liberal_2025.rb` using `find_or_create_by!` for idempotency
- Wired into `db/seeds.rb` after `policy_areas` and `canada` seeds (which must run first to create the Government, Department, and PolicyArea records)

## Limitations

1. **No page numbers.** The PDF text extraction does not preserve page-level boundaries, so `reference` fields in CommitmentSource records don't include page numbers.
2. **Department mapping is approximate.** Some commitments span multiple departments and the lead assignment reflects best judgment, not official government designation.
3. **Criteria are initial.** The generated criteria represent a starting point for the assessment pipeline. They should be refined as evidence collection begins and assessment patterns emerge.
4. **Annex content excluded.** Annex 1 (Fiscal Plan) and Annex 2 (GBA+ Analysis) were not extracted as commitments since they contain fiscal projections and analytical frameworks rather than discrete promises.
5. **Parent-child decomposition is minimal.** Most compound bullets were extracted as individual commitments rather than using parent-child groupings, since each bullet typically contained a single verifiable promise. Future enrichment may add more hierarchical structure.
