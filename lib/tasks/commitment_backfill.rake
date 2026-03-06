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

      puts "\nPhases must run sequentially. After criteria jobs finish, run:"
      puts "  rake commitments:backfill:entries"
      puts "  rake commitments:backfill:bills"
      puts "  rake commitments:backfill:statcan"
      puts "Then after those finish:"
      puts "  rake commitments:backfill:assess"
    end
  end
end
