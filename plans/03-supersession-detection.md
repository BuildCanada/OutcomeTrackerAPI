# Plan 3: Supersession & Abandonment Detection

## Goal

When new source documents add commitments (via Plan 1), automatically detect if existing commitments are superseded or abandoned by the new document.

## Problem

When a new budget, throne speech, or platform is released, it may replace or drop previous commitments. Without detection, stale commitments remain as `not_started` or `in_progress` indefinitely.

## Architecture

This integrates as the final step of Plan 1's `SourceDocumentProcessorJob`:

```
SourceDocumentProcessorJob
  -> ... (extraction steps from Plan 1) ...
  -> Step 7: CommitmentReconciler (big model)
    -> Compare new commitments against existing ones
    -> Mark superseded commitments with superseded_by_id
    -> Mark abandoned commitments
    -> Create CriterionAssessment audit records
```

## Chat Subclass

### `CommitmentReconciler` (big model: `gemini-3.1-pro-preview`)

```ruby
class CommitmentReconciler < Chat
  include Structify::Model

  schema_definition do
    version 1
    name "CommitmentReconciler"
    description "Detects superseded and abandoned commitments when new source documents are processed"
    field :changes, :array,
      description: "Status changes for existing commitments. Only include commitments that should change.",
      items: {
        type: "object", properties: {
          "existing_commitment_id" => { type: "integer", description: "ID of the existing commitment" },
          "action" => { type: "string", enum: ["superseded", "abandoned"],
            description: "superseded = replaced by a new commitment; abandoned = dropped entirely" },
          "superseded_by_title" => { type: "string",
            description: "Title of the NEW commitment that replaces this one. Only for superseded." },
          "reasoning" => { type: "string",
            description: "Explanation of why this commitment is superseded or abandoned" }
        }
      }
  end

  def prompt(new_commitments, existing_commitments, source_document)
    <<~PROMPT
    You are analyzing a new government document to determine if it supersedes or abandons any existing commitments.

    CONTEXT:
    New document: "#{source_document.title}" (#{source_document.source_type}, dated #{source_document.date})

    A commitment is SUPERSEDED when:
    - The new document contains a commitment that replaces it with different targets, mechanisms, or scope
    - The new commitment explicitly modifies or replaces the old one
    - Example: Platform says "Build 500,000 homes" -> Budget says "Build 300,000 homes with different funding" = superseded

    A commitment is ABANDONED when:
    - The new document covers the same policy area but conspicuously omits this commitment
    - The government has explicitly stated they are no longer pursuing this
    - Do NOT mark as abandoned just because a document doesn't mention it -- only if the omission is significant
    - Example: A throne speech focuses on housing but drops a specific housing promise from the platform

    Be CONSERVATIVE. Only flag changes you are confident about. It's better to miss a supersession than to falsely mark a commitment.

    EXISTING COMMITMENTS:
    #{existing_commitments.map { |c| "ID #{c.id}: [#{c.commitment_type}] #{c.title}\n  Description: #{c.description}" }.join("\n\n")}

    NEW COMMITMENTS FROM THIS DOCUMENT:
    #{new_commitments.map { |title, c| "#{c.title}\n  Description: #{c.description}" }.join("\n\n")}

    Return only commitments that should change status. Return an empty array if no changes detected.
    PROMPT
  end

  def reconcile!(new_commitments, existing_commitments, source)
    self.extract!(prompt(new_commitments, existing_commitments, record))

    new_by_title = new_commitments.transform_keys(&:downcase)

    changes.each do |change|
      commitment = Commitment.find_by(id: change["existing_commitment_id"])
      next unless commitment

      case change["action"]
      when "superseded"
        superseding = new_by_title[change["superseded_by_title"]&.downcase]
        commitment.update!(
          status: :superseded,
          superseded_by: superseding
        )
      when "abandoned"
        commitment.update!(status: :abandoned)
      end

      # Create audit trail on all criteria
      commitment.criteria.each do |criterion|
        CriterionAssessment.create!(
          criterion: criterion,
          previous_status: criterion.status,
          new_status: :no_longer_applicable,
          source: source,
          evidence_notes: "#{change['action'].capitalize}: #{change['reasoning']}",
          assessed_at: Time.current
        )
        criterion.update!(status: :no_longer_applicable, assessed_at: Time.current)
      end
    end
  end
end
```

## Integration with Plan 1

In `SourceDocumentProcessorJob`, after Step 6 (set parent relationships):

```ruby
# Step 7: Reconcile with existing commitments
existing_active = Commitment.where(government: source_document.government)
  .where.not(status: [:abandoned, :superseded])
  .where.not(id: created_commitments.values.map(&:id))

if existing_active.any? && created_commitments.any?
  reconciler = CommitmentReconciler.create!(record: source_document)
  reconciler.reconcile!(created_commitments, existing_active, source)
end
```

## Files to Create

| File | Purpose |
|---|---|
| `app/models/commitment_reconciler.rb` | Big model Chat subclass |

## Files to Modify

| File | Change |
|---|---|
| `app/jobs/source_document_processor_job.rb` | Add reconciliation step (Step 7) |

## Verification

1. Create a mock "Budget 2026" document that:
   - Replaces a platform spending commitment with a different funding amount
   - Covers defence but drops a specific defence commitment
2. Upload via Avo
3. Verify the replaced commitment is marked `superseded` with correct `superseded_by_id`
4. Verify the dropped commitment is marked `abandoned`
5. Verify CriterionAssessment audit records are created for all criteria on affected commitments
6. Verify no false positives (commitments that shouldn't change remain unchanged)
