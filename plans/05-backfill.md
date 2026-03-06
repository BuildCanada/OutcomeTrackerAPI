# Plan 5: Backfilling Existing Data

## Goal

Run the assessment pipeline (Plan 4) against all existing entries, bills, and StatCan data to bootstrap commitment evaluations from day one.

## Dependencies

- **Plan 2** (Criteria Generation) must be implemented and run first
- **Plan 4** (Assessment Pipeline) must be implemented first
- This plan is primarily rake tasks that invoke Plan 2 + Plan 4 infrastructure

## Rake Tasks

### `lib/tasks/commitment_backfill.rake`

```ruby
namespace :commitments do
  namespace :backfill do
    desc "Phase 1: Generate criteria for all commitments"
    task criteria: :environment do
      count = 0
      Commitment.where(criteria_generated_at: nil).find_each do |commitment|
        CriteriaGeneratorJob.perform_later(commitment)
        count += 1
      end
      puts "Enqueued criteria generation for #{count} commitments"
    end

    desc "Phase 2: Filter existing entries for commitment relevance"
    task entries: :environment do
      count = 0
      Entry.where.not(activities_extracted_at: nil)
           .where(skipped_at: nil)
           .find_each do |entry|
        CommitmentRelevanceFilterJob.perform_later(entry)
        count += 1
      end
      puts "Enqueued relevance filtering for #{count} entries"
    end

    desc "Phase 3: Filter existing bills for commitment relevance"
    task bills: :environment do
      count = 0
      Bill.find_each do |bill|
        CommitmentRelevanceFilterJob.perform_later(bill)
        count += 1
      end
      puts "Enqueued relevance filtering for #{count} bills"
    end

    desc "Phase 4: Filter existing StatCan datasets for commitment relevance"
    task statcan: :environment do
      count = 0
      StatcanDataset.where.not(current_data: nil).find_each do |dataset|
        CommitmentRelevanceFilterJob.perform_later(dataset)
        count += 1
      end
      puts "Enqueued relevance filtering for #{count} StatCan datasets"
    end

    desc "Phase 5: Run initial assessment on all commitments with unassessed matches"
    task assess: :environment do
      count = 0
      commitment_ids = CommitmentMatch.unassessed.high_relevance
        .select(:commitment_id).distinct.pluck(:commitment_id)

      Commitment.where(id: commitment_ids).find_each do |commitment|
        CommitmentAssessmentJob.perform_later(commitment)
        count += 1
      end
      puts "Enqueued assessment for #{count} commitments"
    end

    desc "Run all backfill phases in sequence"
    task all: :environment do
      puts "=== Phase 1: Generate Criteria ==="
      Rake::Task["commitments:backfill:criteria"].invoke

      puts "\nWaiting for criteria generation to complete..."
      puts "Run 'rake commitments:backfill:entries' after criteria jobs finish."
      puts "Then 'rake commitments:backfill:bills'"
      puts "Then 'rake commitments:backfill:statcan'"
      puts "Then 'rake commitments:backfill:assess'"
    end
  end
end
```

## Execution Order

Phases must be run sequentially because each depends on the previous:

1. **`rake commitments:backfill:criteria`** - Must complete before assessment can run
2. **`rake commitments:backfill:entries`** - Can run in parallel with bills/statcan
3. **`rake commitments:backfill:bills`** - Can run in parallel with entries/statcan
4. **`rake commitments:backfill:statcan`** - Can run in parallel with entries/bills
5. **`rake commitments:backfill:assess`** - Must run after all filtering is done

Phase 1 must finish before Phase 5. Phases 2-4 can run in parallel but must finish before Phase 5.

## Cost Estimate

- **Phase 1 (Criteria):** ~290 big model calls (1 per commitment)
- **Phase 2 (Entries):** ~N small model calls x (290/20) batches per call. If 500 entries: ~7,500 small model calls
- **Phase 3 (Bills):** ~M small model calls x 15 batches. If 200 bills: ~3,000 small model calls
- **Phase 4 (StatCan):** Minimal - likely <100 small model calls
- **Phase 5 (Assess):** ~K big model calls x criteria per commitment. If 100 commitments have matches with avg 5 criteria: ~500 big model calls

Total: ~290 big + ~10,600 small (Phase 1-4) + ~500 big (Phase 5) = ~790 big + ~10,600 small model calls.

## Files to Create

| File | Purpose |
|---|---|
| `lib/tasks/commitment_backfill.rake` | All rake tasks |

## Verification

1. Run `rake commitments:backfill:criteria` - verify all commitments get criteria
2. Run `rake commitments:backfill:entries` - verify CommitmentMatch records created
3. Run `rake commitments:backfill:assess` - verify criteria get assessed and statuses update
4. Spot-check 10 commitments across different types:
   - Do matched entries make sense for the commitment?
   - Are criteria assessments reasonable?
   - Does the derived status match reality?
