# Plan 2: Evaluation Criteria Generation

## Goal

Generate high-quality, type-specific evaluation criteria for all commitments, replacing the current pattern of exactly 1 success + 1 execution criterion per commitment with 0 progress criteria.

## Problem

Current criteria quality is poor:
- Exactly 1 success + 1 execution criterion per commitment, zero progress
- 183/290 success criteria are borderline measurable (no quantitative targets)
- 34 spending commitments lack funding language in criteria
- 55 vague verification methods vs 62 with specific data sources
- Makes lifecycle tracking and scorecards binary instead of nuanced

## Architecture

```
CriteriaGenerationCronJob (periodic or manual)
  -> Find commitments needing criteria generation
  -> For each: CriteriaGeneratorJob
    -> CriteriaGenerator (big model)
    -> Delete existing not_assessed criteria
    -> Create new Criterion records
    -> Update commitment.criteria_generated_at
```

## Migration

### `add_criteria_generated_at_to_commitments`

```ruby
class AddCriteriaGeneratedAtToCommitments < ActiveRecord::Migration[8.0]
  def change
    add_column :commitments, :criteria_generated_at, :datetime
  end
end
```

## Chat Subclass

### `CriteriaGenerator` (big model: `gemini-3.1-pro-preview`)

```ruby
class CriteriaGenerator < Chat
  include Structify::Model

  schema_definition do
    version 1
    name "CriteriaGenerator"
    description "Generates assessment criteria for a commitment"
    field :criteria, :array,
      description: "Assessment criteria across three categories",
      items: {
        type: "object", properties: {
          "category" => { type: "string", enum: ["success", "execution", "progress"],
            description: "success = what done looks like, execution = observable steps, progress = intermediate indicators" },
          "description" => { type: "string",
            description: "Specific, measurable criterion. Include quantitative targets where possible." },
          "verification_method" => { type: "string",
            description: "Specific data source or method to check. Must name actual sources (LEGISinfo, Budget docs, StatCan table, etc.)" },
          "position" => { type: "integer", description: "Display order within category (0-indexed)" }
        }
      }
  end

  def prompt(commitment)
    <<~PROMPT
    You are a government accountability analyst generating assessment criteria for a Canadian federal government commitment.

    COMMITMENT:
    Title: #{commitment.title}
    Description: #{commitment.description}
    Original Text: #{commitment.original_text}
    Type: #{commitment.commitment_type}
    Policy Area: #{commitment.policy_area&.name}
    Lead Department: #{commitment.lead_department&.display_name}
    All Departments: #{commitment.departments.map(&:display_name).join(', ')}

    GENERATE CRITERIA following these rules:

    SUCCESS CRITERIA (2-4):
    - Define the end state: "If all these are met, the commitment is fulfilled"
    - Include QUANTITATIVE targets where the commitment states them
    - For spending: specify the dollar amount and where funds must flow
    - For legislative: specify Royal Assent + operational date
    - For outcome: specify the measurable indicator and target value
    - Each criterion must be independently verifiable

    EXECUTION CRITERIA (2-3):
    - Observable government actions that indicate work is happening
    - Help distinguish "in progress" from "not started"
    - Examples: legislation tabled, budget line item created, consultation launched, procurement issued
    - Tied to specific parliamentary or bureaucratic milestones

    PROGRESS CRITERIA (1-2):
    - Intermediate measurable indicators that track partial progress
    - Useful for multi-year commitments
    - Examples: spending as % of target, units delivered vs target, stages completed
    - Should reference specific data sources (StatCan tables, departmental reports, etc.)

    VERIFICATION METHOD RULES:
    - MUST name a specific data source, not "Monitor government announcements"
    - Good: "LEGISinfo bill tracking for C-XX", "Federal Budget Chapter 3", "StatCan Table 36-10-0222-01"
    - Good: "DND Departmental Results Report", "Main Estimates Part II", "Canada Gazette Part II"
    - Bad: "Review government reports", "Check media coverage", "Monitor progress"

    TYPE-SPECIFIC GUIDANCE:
    #{type_guidance(commitment.commitment_type)}

    Return criteria as a JSON array.
    PROMPT
  end

  private

  def type_guidance(commitment_type)
    case commitment_type
    when "legislative"
      <<~GUIDE
      - Success: Bill receives Royal Assent, regulations published in Canada Gazette
      - Execution: Bill tabled in Parliament, passes committee, passes House/Senate readings
      - Progress: Bill stage progression (1st reading -> 2nd -> committee -> 3rd -> Senate)
      - Verification: LEGISinfo, Canada Gazette Part II, Hansard
      GUIDE
    when "spending"
      <<~GUIDE
      - Success: Full funding amount allocated AND disbursed
      - Execution: Budget line item created, Main Estimates allocation, program launched
      - Progress: Spending as % of committed amount, year-over-year increase
      - Verification: Federal Budget, Main Estimates, Supplementary Estimates, Public Accounts, Departmental Plans
      GUIDE
    when "procedural"
      <<~GUIDE
      - Success: New process/review completed and implemented
      - Execution: Review launched, consultations held, report published
      - Progress: Timeline milestones met, stakeholder engagement completed
      - Verification: Canada Gazette, Order in Council database, departmental websites
      GUIDE
    when "institutional"
      <<~GUIDE
      - Success: Organization exists, is staffed, and operational
      - Execution: Enabling legislation/order, appointments made, budget allocated
      - Progress: Staffing levels, operational milestones
      - Verification: GIC appointments, Canada Gazette, departmental org charts
      GUIDE
    when "diplomatic"
      <<~GUIDE
      - Success: Agreement signed/ratified, obligations met
      - Execution: Negotiations initiated, framework agreed, domestic legislation passed
      - Progress: Negotiation stages completed, partner commitments secured
      - Verification: GAC treaty database, joint statements, UN/NATO communiques
      GUIDE
    when "outcome"
      <<~GUIDE
      - Success: Measurable target achieved (specify the number)
      - Execution: Programs launched to drive the outcome, funding allocated
      - Progress: Indicator moving toward target (specify the StatCan table or data source)
      - Verification: StatCan indicators, departmental results reports, third-party reports
      GUIDE
    when "aspirational"
      <<~GUIDE
      - Success: Directional indicators show improvement (specify which ones)
      - Execution: Concrete programs or policies launched in this direction
      - Progress: Related measurable indicators trending positively
      - Verification: StatCan, departmental reports, international rankings
      GUIDE
    end
  end

  def generate_criteria!
    raise ArgumentError, "Record must be a Commitment" unless record.is_a?(Commitment)

    self.extract!(prompt(record))

    # Delete existing not_assessed criteria (preserve any that have been assessed)
    record.criteria.where(status: :not_assessed).destroy_all

    criteria.each do |criterion_data|
      Criterion.create!(
        commitment: record,
        category: criterion_data["category"],
        description: criterion_data["description"],
        verification_method: criterion_data["verification_method"],
        status: :not_assessed,
        position: criterion_data["position"] || 0
      )
    end

    record.update!(criteria_generated_at: Time.current)
  end
end
```

## Jobs

### `CriteriaGeneratorJob`

```ruby
class CriteriaGeneratorJob < ApplicationJob
  queue_as :default

  def perform(commitment)
    generator = CriteriaGenerator.create!(record: commitment)
    generator.generate_criteria!
  end
end
```

### `CriteriaGenerationCronJob` (optional orchestrator)

```ruby
class CriteriaGenerationCronJob < ApplicationJob
  queue_as :default

  def perform
    # Find commitments without generated criteria
    Commitment.where(criteria_generated_at: nil).find_each do |commitment|
      CriteriaGeneratorJob.perform_later(commitment)
    end
  end
end
```

## Model Changes

### `app/models/commitment.rb`

Add method:

```ruby
def generate_criteria!(inline: false)
  unless inline
    return CriteriaGeneratorJob.perform_later(self)
  end

  generator = CriteriaGenerator.create!(record: self)
  generator.generate_criteria!
end
```

## Files to Create

| File | Purpose |
|---|---|
| `app/models/criteria_generator.rb` | Big model Chat subclass |
| `app/jobs/criteria_generator_job.rb` | Per-commitment job |
| `app/jobs/criteria_generation_cron_job.rb` | Orchestrator (optional) |
| `db/migrate/..._add_criteria_generated_at_to_commitments.rb` | Tracking column |

## Files to Modify

| File | Change |
|---|---|
| `app/models/commitment.rb` | Add `generate_criteria!` method |
| `config/initializers/good_job.rb` | Optionally add cron entry |

## Verification

1. Run `CriteriaGeneratorJob` on 10 sample commitments (2 of each major type)
2. Verify each commitment now has:
   - 2-4 success criteria with quantitative targets where applicable
   - 2-3 execution criteria with specific milestones
   - 1-2 progress criteria with data source references
3. Verify spending commitments mention dollar amounts and budget documents
4. Verify legislative commitments reference bill stages and LEGISinfo
5. Verify verification_methods cite specific data sources (not generic "monitor progress")
6. Verify existing assessed criteria are NOT deleted (only `not_assessed` ones replaced)
