# Plan 4: Assessment Pipeline

## Goal

Two-tier LLM pipeline that matches incoming data (entries, bills, StatCan) to commitments using a cheap model, then assesses criteria using a big model.

## Architecture

### Tier 1: Relevance Filtering (small model, per data item)

```
New Entry / Bill update / StatCan sync
  -> CommitmentRelevanceFilterJob
    -> CommitmentRelevanceFilter (gemini-3.1-flash-lite-preview)
    -> Batches of 20 commitments per LLM call
    -> Creates CommitmentMatch records (relevance_score >= 0.5)
```

### Tier 2: Criterion Assessment (big model, per commitment, periodic)

```
CommitmentAssessmentCronJob (every 6 hours)
  -> Find commitments with unassessed CommitmentMatch records
  -> For each: CommitmentAssessmentJob
    -> Ensure criteria exist (call Plan 2 if needed)
    -> For each criterion: CriterionAssessor (gemini-3.1-pro-preview)
    -> Create CriterionAssessment audit records on status change
    -> Derive Commitment#status from criteria roll-up
    -> Update Commitment#last_assessed_at
```

## New Model: `CommitmentMatch`

### Migration: `create_commitment_matches`

```ruby
class CreateCommitmentMatches < ActiveRecord::Migration[8.0]
  def change
    create_table :commitment_matches do |t|
      t.references :commitment, null: false, foreign_key: true
      t.string :matchable_type, null: false
      t.bigint :matchable_id, null: false
      t.float :relevance_score, null: false
      t.text :relevance_reasoning
      t.datetime :matched_at, null: false
      t.boolean :assessed, default: false, null: false
      t.datetime :assessed_at
      t.jsonb :metadata, default: {}
      t.timestamps
    end

    add_index :commitment_matches, [:commitment_id, :matchable_type, :matchable_id],
              unique: true, name: "idx_commitment_matches_unique"
    add_index :commitment_matches, [:matchable_type, :matchable_id],
              name: "idx_commitment_matches_matchable"
    add_index :commitment_matches, [:commitment_id, :assessed],
              name: "idx_commitment_matches_unassessed"
  end
end
```

### Model

```ruby
class CommitmentMatch < ApplicationRecord
  belongs_to :commitment
  belongs_to :matchable, polymorphic: true

  scope :unassessed, -> { where(assessed: false) }
  scope :high_relevance, -> { where("relevance_score >= ?", 0.6) }

  validates :relevance_score, presence: true,
    numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 1 }
end
```

## Chat Subclasses

### `CommitmentRelevanceFilter` (small model: `gemini-3.1-flash-lite-preview`)

```ruby
class CommitmentRelevanceFilter < Chat
  include Structify::Model

  schema_definition do
    version 1
    name "CommitmentRelevanceFilter"
    description "Determines which commitments a data item is relevant to"
    field :matches, :array,
      description: "Commitments this data item is relevant to. Empty array if none.",
      items: {
        type: "object", properties: {
          "commitment_id" => { type: "integer" },
          "relevance_score" => { type: "number", description: "0.0 to 1.0" },
          "relevance_reasoning" => { type: "string", description: "1-2 sentences max" }
        }
      }
  end

  def prompt_for_entry(commitments_batch, entry)
    <<~PROMPT
    Determine which government commitments this news/document relates to.

    COMMITMENTS:
    #{format_commitments(commitments_batch)}

    DOCUMENT:
    #{entry.format_for_llm}

    Return ONLY commitments that this document provides evidence for or against.
    Score 0.8-1.0 = directly about this commitment
    Score 0.5-0.7 = indirectly relevant (related policy area, department action)
    Do NOT match on vague thematic similarity. The document must contain specific information relevant to evaluating the commitment.
    PROMPT
  end

  def prompt_for_bill(commitments_batch, bill)
    <<~PROMPT
    Determine which government commitments this parliamentary bill relates to.

    COMMITMENTS:
    #{format_commitments(commitments_batch)}

    BILL:
    Bill Number: #{bill.bill_number_formatted}
    Short Title: #{bill.short_title}
    Long Title: #{bill.long_title}
    Latest Activity: #{bill.latest_activity}
    House Stages: 1R=#{bill.passed_house_first_reading_at&.to_date} 2R=#{bill.passed_house_second_reading_at&.to_date} 3R=#{bill.passed_house_third_reading_at&.to_date}
    Senate Stages: 1R=#{bill.passed_senate_first_reading_at&.to_date} 2R=#{bill.passed_senate_second_reading_at&.to_date} 3R=#{bill.passed_senate_third_reading_at&.to_date}
    Royal Assent: #{bill.received_royal_assent_at&.to_date}

    Return ONLY commitments that this bill directly implements or advances.
    PROMPT
  end

  def prompt_for_statcan(commitments_batch, dataset)
    <<~PROMPT
    Determine which government commitments this Statistics Canada dataset is relevant to.

    COMMITMENTS:
    #{format_commitments(commitments_batch)}

    DATASET:
    Name: #{dataset.name}
    URL: #{dataset.statcan_url}
    Last Synced: #{dataset.last_synced_at}
    Data Summary: #{dataset.current_data&.first(5)&.to_json}

    Return ONLY commitments whose success or progress criteria could be measured using this dataset.
    PROMPT
  end

  def filter_relevance!(matchable)
    government_id = matchable.respond_to?(:government_id) ? matchable.government_id : nil
    commitments = if government_id
      Commitment.where(government_id: government_id).where.not(status: [:abandoned, :superseded])
    else
      Commitment.where.not(status: [:abandoned, :superseded])
    end

    prompt_method = case matchable
    when Entry then :prompt_for_entry
    when Bill then :prompt_for_bill
    when StatcanDataset then :prompt_for_statcan
    end

    # Batch 20 commitments per LLM call
    commitments.find_in_batches(batch_size: 20) do |batch|
      filter = CommitmentRelevanceFilter.create!(record: matchable)
      filter.extract!(filter.send(prompt_method, batch, matchable))

      filter.matches.each do |match_data|
        next if match_data["relevance_score"] < 0.5

        CommitmentMatch.find_or_create_by!(
          commitment_id: match_data["commitment_id"],
          matchable: matchable
        ) do |cm|
          cm.relevance_score = match_data["relevance_score"]
          cm.relevance_reasoning = match_data["relevance_reasoning"]
          cm.matched_at = Time.current
        end
      end
    end
  end

  private

  def format_commitments(batch)
    batch.map { |c| "ID #{c.id}: [#{c.commitment_type}] #{c.title} — #{c.description.truncate(150)}" }.join("\n")
  end
end
```

### `CriterionAssessor` (big model: `gemini-3.1-pro-preview`)

```ruby
class CriterionAssessor < Chat
  include Structify::Model

  schema_definition do
    version 1
    name "CriterionAssessor"
    description "Assesses a criterion against matched evidence"
    field :assessment, :object, properties: {
      "new_status" => { type: "string", enum: ["not_assessed", "met", "partially_met", "not_met", "no_longer_applicable"] },
      "evidence_notes" => { type: "string", description: "Explanation referencing specific evidence" },
      "confidence" => { type: "number", description: "0.0 to 1.0" }
    }
  end

  def prompt(criterion, evidence_items)
    <<~PROMPT
    You are assessing a specific criterion for a government commitment based on available evidence.

    COMMITMENT:
    Title: #{criterion.commitment.title}
    Description: #{criterion.commitment.description}
    Type: #{criterion.commitment.commitment_type}

    CRITERION TO ASSESS:
    Category: #{criterion.category}
    Description: #{criterion.description}
    Verification Method: #{criterion.verification_method}
    Current Status: #{criterion.status}
    Previous Evidence: #{criterion.evidence_notes}

    MATCHED EVIDENCE:
    #{format_evidence(evidence_items)}

    ASSESSMENT RULES:
    - met: Clear evidence that this criterion is fully satisfied
    - partially_met: Some evidence of progress but not complete
    - not_met: Evidence exists but shows criterion is not satisfied, or contradictory evidence
    - not_assessed: Insufficient evidence to make any determination
    - no_longer_applicable: The commitment has been superseded or the criterion is moot

    Be CONSERVATIVE. Only mark as "met" if evidence clearly supports it.
    If current status is already "met" and no contradictory evidence, keep it "met".
    Reference specific evidence items in your evidence_notes.
    PROMPT
  end

  def assess!(criterion, matches)
    evidence_items = matches.map(&:matchable)
    self.extract!(prompt(criterion, evidence_items))

    new_status = assessment["new_status"]
    return if new_status == criterion.status # No change

    # Find source for audit trail (create from match if needed)
    source = find_or_create_source(matches.first)

    CriterionAssessment.create!(
      criterion: criterion,
      previous_status: criterion.status,
      new_status: new_status,
      source: source,
      evidence_notes: assessment["evidence_notes"],
      assessed_at: Time.current
    )

    criterion.update!(
      status: new_status,
      evidence_notes: assessment["evidence_notes"],
      assessed_at: Time.current
    )
  end

  private

  def format_evidence(items)
    items.map do |item|
      case item
      when Entry
        "ENTRY: #{item.title} (#{item.published_at&.to_date})\n#{item.parsed_markdown&.truncate(1000)}"
      when Bill
        "BILL: #{item.bill_number_formatted} - #{item.short_title}\nLatest: #{item.latest_activity} (#{item.latest_activity_at&.to_date})"
      when StatcanDataset
        "STATCAN: #{item.name}\nData: #{item.current_data&.first(3)&.to_json}"
      end
    end.join("\n\n---\n\n")
  end

  def find_or_create_source(match)
    # Only create Source records for high-confidence matches
    nil # Sources are created manually or via Plan 1; assessment just references them
  end
end
```

## Jobs

### `CommitmentRelevanceFilterJob`

```ruby
class CommitmentRelevanceFilterJob < ApplicationJob
  queue_as :default

  def perform(matchable)
    filter = CommitmentRelevanceFilter.create!(record: matchable)
    filter.filter_relevance!(matchable)
  end
end
```

### `CommitmentAssessmentJob`

```ruby
class CommitmentAssessmentJob < ApplicationJob
  queue_as :default

  def perform(commitment)
    # Ensure criteria exist
    if commitment.criteria.empty?
      commitment.generate_criteria!(inline: true)
    end

    unassessed_matches = commitment.commitment_matches.unassessed.high_relevance
    return if unassessed_matches.empty?

    evidence_items = unassessed_matches.includes(:matchable)

    commitment.criteria.find_each do |criterion|
      assessor = CriterionAssessor.create!(record: criterion)
      assessor.assess!(criterion, evidence_items)
    end

    unassessed_matches.update_all(assessed: true, assessed_at: Time.current)
    commitment.update!(last_assessed_at: Time.current)
    commitment.derive_status_from_criteria!
  end
end
```

### `CommitmentAssessmentCronJob`

```ruby
class CommitmentAssessmentCronJob < ApplicationJob
  queue_as :default

  def perform
    commitment_ids = CommitmentMatch.unassessed.high_relevance
      .select(:commitment_id).distinct.pluck(:commitment_id)

    Commitment.where(id: commitment_ids).find_each do |commitment|
      CommitmentAssessmentJob.perform_later(commitment)
    end
  end
end
```

## Model Changes

### `app/models/commitment.rb`

Add:

```ruby
has_many :commitment_matches, dependent: :destroy

def derive_status_from_criteria!
  success = success_criteria.to_a
  execution = execution_criteria.to_a
  return if success.empty?

  if success.all?(&:met?)
    update!(status: :implemented)
  elsif success.any? { |c| c.met? || c.partially_met? }
    if execution.any? { |c| c.met? || c.partially_met? }
      update!(status: :partially_implemented)
    else
      update!(status: :in_progress)
    end
  elsif execution.any? { |c| c.met? || c.partially_met? }
    update!(status: :in_progress)
  end
  # not_started, abandoned, superseded are not derived
end
```

### `app/models/entry.rb`

Add after `extract_activities!` call in `fetch_data!`:

```ruby
has_many :commitment_matches, as: :matchable, dependent: :destroy

def filter_commitment_relevance!(inline: false)
  unless inline
    return CommitmentRelevanceFilterJob.perform_later(self)
  end
  filter = CommitmentRelevanceFilter.create!(record: self)
  filter.filter_relevance!(self)
end
```

In `fetch_data!`, after line 65 (`extract_activities!`), add:

```ruby
filter_commitment_relevance!
```

### `app/models/bill.rb`

Add:

```ruby
has_many :commitment_matches, as: :matchable, dependent: :destroy

def format_for_llm
  { bill_number: bill_number_formatted, short_title: short_title, long_title: long_title,
    latest_activity: latest_activity, latest_activity_at: latest_activity_at }
end

def filter_commitment_relevance!(inline: false)
  unless inline
    return CommitmentRelevanceFilterJob.perform_later(self)
  end
  filter = CommitmentRelevanceFilter.create!(record: self)
  filter.filter_relevance!(self)
end
```

### `app/models/statcan_dataset.rb`

Add:

```ruby
has_many :commitment_matches, as: :matchable, dependent: :destroy

def format_for_llm
  { name: name, url: statcan_url, data_preview: current_data&.first(5) }
end

def filter_commitment_relevance!(inline: false)
  unless inline
    return CommitmentRelevanceFilterJob.perform_later(self)
  end
  filter = CommitmentRelevanceFilter.create!(record: self)
  filter.filter_relevance!(self)
end
```

## GoodJob Cron

Add to `config/initializers/good_job.rb`:

```ruby
commitment_assessment: {
  cron: "0 */6 * * *",
  class: "CommitmentAssessmentCronJob",
  description: "Assess commitments with new evidence matches",
  enabled_by_default: -> { Rails.env.production? }
}
```

## Files to Create

| File | Purpose |
|---|---|
| `app/models/commitment_match.rb` | Polymorphic join model |
| `app/models/commitment_relevance_filter.rb` | Small model Chat subclass |
| `app/models/criterion_assessor.rb` | Big model Chat subclass |
| `app/jobs/commitment_relevance_filter_job.rb` | Per-data-item job |
| `app/jobs/commitment_assessment_job.rb` | Per-commitment job |
| `app/jobs/commitment_assessment_cron_job.rb` | 6-hour orchestrator |
| `db/migrate/..._create_commitment_matches.rb` | New table |

## Files to Modify

| File | Change |
|---|---|
| `app/models/commitment.rb` | Add associations + `derive_status_from_criteria!` |
| `app/models/entry.rb` | Add `commitment_matches` association, `filter_commitment_relevance!`, hook in `fetch_data!` |
| `app/models/bill.rb` | Add `commitment_matches` association, `format_for_llm`, `filter_commitment_relevance!` |
| `app/models/statcan_dataset.rb` | Add `commitment_matches` association, `format_for_llm`, `filter_commitment_relevance!` |
| `config/initializers/good_job.rb` | Add cron entry |

## Verification

1. Process a known entry about defence spending -> verify CommitmentMatch to defence commitments
2. Process a Criminal Code bill -> verify match to legislative justice commitments
3. Run assessment on a commitment with matches -> verify criteria status updates + CriterionAssessment audit records
4. Verify commitment status derivation: all success met -> implemented, some met -> in_progress
5. Verify 6-hour cron finds and processes commitments with unassessed matches
