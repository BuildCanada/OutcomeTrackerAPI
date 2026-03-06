# Plan 1: Commitment Extraction Pipeline

## Goal

Let admins upload a source document (PDF) in Avo, which kicks off a multi-stage pipeline to extract, deduplicate, and structure commitments. Replaces the current single-pass extraction that produced poor quality data (no hierarchy, duplicate descriptions, vague criteria).

## Problem

The current 290 commitments were extracted in one LLM pass without chunking or quality gates:
- 10 near-duplicate pairs
- 289/290 have no parent hierarchy
- 118/290 descriptions are >80% identical to original_text
- ~25 policy area misclassifications

## Architecture

```
Admin uploads PDF via Avo
  -> SourceDocument created (ActiveStorage attachment)
  -> SourceDocumentProcessorJob enqueued
    -> Step 1: PDF text extraction (pdf-reader gem, page by page)
    -> Step 2: DocumentChunker (small model) splits into logical sections
    -> Step 3: CommitmentExtractor (big model) per chunk, with existing commitments for dedup
    -> Step 4: Deduplicate across chunks
    -> Step 5: Create Source + Commitments + CommitmentSources + CommitmentDepartments
    -> Step 6: Set parent-child relationships
    -> Step 7: CommitmentReconciler (big model) - detect superseded/abandoned (Plan 3)
    -> Update SourceDocument status
```

## New Model: `SourceDocument`

Represents an uploaded document before it becomes structured Sources + Commitments.

### Migration: `create_source_documents`

```ruby
create_table :source_documents do |t|
  t.references :government, null: false, foreign_key: true
  t.integer :source_type, null: false  # reuse Source enum values
  t.string :title, null: false
  t.string :url
  t.date :date
  t.integer :status, default: 0, null: false  # pending/processing/extracted/failed
  t.jsonb :extraction_metadata, default: {}
  t.text :error_message
  t.timestamps
end
```

### Model

```ruby
class SourceDocument < ApplicationRecord
  belongs_to :government
  has_one_attached :document
  has_one :source  # created after extraction

  enum :status, { pending: 0, processing: 1, extracted: 2, failed: 3 }
  enum :source_type, Source.source_types  # reuse the same enum

  validates :title, presence: true
  validates :source_type, presence: true
  validates :document, presence: true, on: :create
end
```

## Chat Subclasses

### `DocumentChunker` (small model: `gemini-3.1-flash-lite-preview`)

Takes raw PDF text with page markers, outputs logical chunks with section headers.

```ruby
class DocumentChunker < Chat
  include Structify::Model

  schema_definition do
    version 1
    name "DocumentChunker"
    field :chunks, :array,
      description: "Logical sections of the document, each containing related commitments",
      items: {
        type: "object", properties: {
          "section_title" => { type: "string", description: "Section heading (e.g. 'UNITE - One Canadian Economy')" },
          "content" => { type: "string", description: "Full text of the section" },
          "page_range" => { type: "string", description: "Page range, e.g. '12-15'" }
        }
      }
  end

  def prompt(pdf_text)
    <<~PROMPT
    You are processing a government policy document. Split it into logical sections
    that each contain a coherent set of commitments/promises.

    Rules:
    - Each chunk should be a self-contained section (e.g., a chapter or major topic area)
    - Preserve ALL text - do not summarize or truncate
    - Include section headers/titles from the document
    - Each chunk should be small enough to analyze individually (max ~3000 words)
    - Track page numbers from the [PAGE X] markers in the text

    Document text:
    #{pdf_text}
    PROMPT
  end
end
```

### `CommitmentExtractor` (big model: `gemini-3.1-pro-preview`)

Takes one chunk + list of existing commitment titles (for dedup), outputs structured commitments.

```ruby
class CommitmentExtractor < Chat
  include Structify::Model

  schema_definition do
    version 1
    name "CommitmentExtractor"
    field :commitments, :array,
      items: {
        type: "object", properties: {
          "title" => { type: "string", description: "Specific, action-oriented title. Not a copy of the original text." },
          "description" => { type: "string", description: "Precise description of what was promised. Must add analytical value beyond original_text." },
          "original_text" => { type: "string", description: "Verbatim text from the document" },
          "commitment_type" => { type: "string", enum: %w[legislative spending procedural institutional diplomatic outcome aspirational] },
          "policy_area_slug" => { type: "string" },
          "department_slugs" => { type: "array", items: { type: "object", properties: {
            "slug" => { type: "string" }, "is_lead" => { type: "boolean" }
          }}},
          "parent_title" => { type: "string", description: "Title of parent commitment if this is a child. null for top-level." },
          "source_section" => { type: "string" },
          "source_reference" => { type: "string", description: "Page reference, e.g. 'p. 42'" },
          "existing_commitment_id" => { type: "integer", description: "ID of existing commitment this updates/matches. null if new." },
          "is_duplicate_of" => { type: "string", description: "Title of another commitment in THIS chunk that is a duplicate. null if unique." }
        }
      }
  end

  def prompt(chunk, existing_commitments, policy_areas, departments)
    <<~PROMPT
    You are extracting government commitments from a policy document section.

    STRUCTURING RULES:
    1. ONE verifiable thing per commitment. Compound promises -> parent + children.
    2. Title must be specific and action-oriented: "Increase defence spending to 2% of GDP by 2030" NOT "Strengthen defence"
    3. Description must ADD ANALYTICAL VALUE beyond the original text. Clarify the mechanism, target, or timeline.
    4. If a section has 3+ related commitments, create a parent commitment (type: aspirational) that groups them.
    5. Always preserve the verbatim original_text.
    6. Check existing commitments for duplicates - if this commitment already exists, set existing_commitment_id.

    CLASSIFICATION RULES:
    - spending: Explicit dollar amounts, funding, tax cuts, investment programs
    - legislative: Bills, amendments, Criminal Code changes, new Acts
    - procedural: Process changes, reviews, strategy launches, agency mandates
    - institutional: New agencies, offices, boards
    - outcome: Measurable targets with specific numbers
    - diplomatic: International agreements, treaties, alliances
    - aspirational: Broad directional goals without specific metrics (also use for parent groupings)

    AVAILABLE POLICY AREAS:
    #{policy_areas.map { |pa| "#{pa.slug}: #{pa.name}" }.join("\n")}

    AVAILABLE DEPARTMENTS:
    #{departments.map { |d| "#{d.slug}: #{d.display_name}" }.join("\n")}

    EXISTING COMMITMENTS (check for duplicates):
    #{existing_commitments.map { |c| "ID #{c.id}: #{c.title}" }.join("\n")}

    DOCUMENT SECTION:
    Section: #{chunk['section_title']}
    Pages: #{chunk['page_range']}
    Content:
    #{chunk['content']}
    PROMPT
  end
end
```

## Jobs

### `SourceDocumentProcessorJob`

```ruby
class SourceDocumentProcessorJob < ApplicationJob
  queue_as :default

  def perform(source_document)
    source_document.update!(status: :processing)

    # Step 1: Extract text from PDF
    pdf_text = extract_pdf_text(source_document.document)

    # Step 2: Chunk the document
    chunker = DocumentChunker.create!(record: source_document)
    chunker.extract!(chunker.prompt(pdf_text))
    chunks = chunker.chunks

    # Step 3: Extract commitments per chunk
    existing_commitments = Commitment.where(government: source_document.government)
    policy_areas = PolicyArea.all
    departments = Department.where(government: source_document.government)
    all_extracted = []

    chunks.each do |chunk|
      extractor = CommitmentExtractor.create!(record: source_document)
      extractor.extract!(extractor.prompt(chunk, existing_commitments, policy_areas, departments))
      all_extracted.concat(extractor.commitments.map { |c| c.merge("chunk_section" => chunk["section_title"]) })
    end

    # Step 4: Deduplicate across chunks
    deduped = deduplicate(all_extracted)

    # Step 5: Create records
    source = create_source(source_document)
    created_commitments = create_commitments(deduped, source_document.government, source, policy_areas, departments)

    # Step 6: Set parent-child relationships
    set_parent_relationships(created_commitments, deduped)

    # Step 7: Reconcile with existing commitments (Plan 3)
    # reconcile!(created_commitments, existing_commitments, source)

    source_document.update!(
      status: :extracted,
      extraction_metadata: { commitment_count: created_commitments.size, chunk_count: chunks.size }
    )
  rescue => e
    source_document.update!(status: :failed, error_message: e.message)
    raise
  end

  private

  def extract_pdf_text(attachment)
    # Download to tempfile, extract with pdf-reader
    attachment.open do |file|
      reader = PDF::Reader.new(file.path)
      reader.pages.map.with_index(1) do |page, i|
        "[PAGE #{i}]\n#{page.text}"
      end.join("\n\n")
    end
  end

  def deduplicate(commitments)
    # Remove entries where is_duplicate_of is set
    commitments.reject { |c| c["is_duplicate_of"].present? }
  end

  def create_source(source_document)
    Source.create!(
      government: source_document.government,
      title: source_document.title,
      source_type: source_document.source_type,
      url: source_document.url,
      date: source_document.date
    )
  end

  def create_commitments(extracted, government, source, policy_areas, departments)
    pa_lookup = policy_areas.index_by(&:slug)
    dept_lookup = departments.index_by(&:slug)
    created = {}

    extracted.each do |data|
      if data["existing_commitment_id"].present?
        # Update existing commitment
        commitment = Commitment.find(data["existing_commitment_id"])
        # Link to new source
        CommitmentSource.find_or_create_by!(commitment: commitment, source: source) do |cs|
          cs.section = data["source_section"]
          cs.reference = data["source_reference"]
          cs.excerpt = data["original_text"]&.truncate(500)
        end
        created[data["title"]] = commitment
        next
      end

      commitment = Commitment.create!(
        government: government,
        title: data["title"],
        description: data["description"],
        original_text: data["original_text"],
        commitment_type: data["commitment_type"],
        status: :not_started,
        policy_area: pa_lookup[data["policy_area_slug"]],
        party_code: "LPC",
        region_code: "federal",
        date_promised: source.date
      )

      CommitmentSource.create!(
        commitment: commitment,
        source: source,
        section: data["source_section"],
        reference: data["source_reference"],
        excerpt: data["original_text"]&.truncate(500)
      )

      (data["department_slugs"] || []).each do |dept_data|
        dept = dept_lookup[dept_data["slug"]]
        next unless dept
        CommitmentDepartment.find_or_create_by!(commitment: commitment, department: dept) do |cd|
          cd.is_lead = dept_data["is_lead"] || false
        end
      end

      created[data["title"]] = commitment
    end

    created
  end

  def set_parent_relationships(created, extracted)
    extracted.each do |data|
      next unless data["parent_title"].present?
      child = created[data["title"]]
      parent = created[data["parent_title"]]
      next unless child && parent
      child.update!(parent: parent) unless child.parent_id == parent.id
    end
  end
end
```

## Avo Integration

### `Avo::Resources::SourceDocument`

```ruby
class Avo::Resources::SourceDocument < Avo::BaseResource
  self.title = :title

  def fields
    field :id, as: :id
    field :title, as: :text
    field :source_type, as: :select, enum: ::Source.source_types
    field :document, as: :file
    field :url, as: :text
    field :date, as: :date
    field :status, as: :select, enum: ::SourceDocument.statuses, disabled: true
    field :error_message, as: :textarea, hide_on: :index
    field :extraction_metadata, as: :code, language: :json, hide_on: :index
    field :government, as: :belongs_to
    field :source, as: :has_one
  end
end
```

Add an Avo action "Process Document" or trigger processing via `after_commit` on create.

## Gem Addition

Add to `Gemfile`:
```ruby
gem "pdf-reader", "~> 2.12"
```

## Files to Create

| File | Purpose |
|---|---|
| `app/models/source_document.rb` | Model with ActiveStorage attachment |
| `app/models/document_chunker.rb` | Small model Chat subclass for PDF chunking |
| `app/models/commitment_extractor.rb` | Big model Chat subclass for extraction |
| `app/jobs/source_document_processor_job.rb` | Orchestrator job |
| `app/avo/resources/source_document.rb` | Avo admin resource |
| `app/controllers/avo/source_documents_controller.rb` | Avo controller |
| `db/migrate/..._create_source_documents.rb` | Migration |

## Files to Modify

| File | Change |
|---|---|
| `Gemfile` | Add `pdf-reader` gem |
| `config/routes.rb` | No changes needed (Avo handles routing) |

## Verification

1. Upload Liberal Platform 2025 PDF via Avo admin
2. Confirm SourceDocument status moves: pending -> processing -> extracted
3. Confirm ~290 commitments created with proper hierarchy (parent-child)
4. Verify deduplication (no near-duplicate pairs)
5. Verify descriptions add value beyond original_text
6. Verify policy area classifications are correct
7. Verify department assignments are reasonable
8. Compare quality against current seed data
