namespace :matching do
  desc "Re-assess all commitments that have unassessed high-relevance matches"
  task reassess: :environment do
    commitment_ids = CommitmentMatch.unassessed.high_relevance
      .select(:commitment_id).distinct.pluck(:commitment_id)

    puts "Found #{commitment_ids.size} commitments with unassessed high-relevance matches"

    count = 0
    Commitment.where(id: commitment_ids).find_each do |commitment|
      CommitmentAssessmentJob.perform_later(commitment)
      count += 1
    end

    puts "Enqueued assessment for #{count} commitments"
  end

  desc "Report on commitment statuses and evidence quality"
  task status_report: :environment do
    puts "=" * 70
    puts "COMMITMENT STATUS REPORT"
    puts "=" * 70

    total = Commitment.count
    by_status = Commitment.group(:status).count
    puts "\nBy Status:"
    by_status.each do |status, count|
      pct = (count.to_f / total * 100).round(1)
      puts "  #{status}: #{count} (#{pct}%)"
    end

    puts "\nEvidence Quality:"

    # Commitments with bill matches
    with_bill = CommitmentMatch.where(matchable_type: "Bill")
      .distinct.count(:commitment_id)
    puts "  With bill match: #{with_bill}"

    # With Royal Assent bills
    royal_assent_bill_ids = Bill.where.not(received_royal_assent_at: nil).pluck(:id)
    with_royal_assent = CommitmentMatch.where(matchable_type: "Bill", matchable_id: royal_assent_bill_ids)
      .distinct.count(:commitment_id)
    puts "  With Royal Assent bill: #{with_royal_assent}"

    # With Gazette entries
    gazette_ii_feed = Feed.find_by("title ILIKE ?", "%Gazette Part II%")
    gazette_iii_feed = Feed.find_by("title ILIKE ?", "%Gazette Part III%")

    if gazette_ii_feed
      g2_entry_ids = gazette_ii_feed.entries.pluck(:id)
      with_g2 = CommitmentMatch.where(matchable_type: "Entry", matchable_id: g2_entry_ids)
        .distinct.count(:commitment_id)
      puts "  With Gazette Part II match: #{with_g2}"
    end

    if gazette_iii_feed
      g3_entry_ids = gazette_iii_feed.entries.pluck(:id)
      with_g3 = CommitmentMatch.where(matchable_type: "Entry", matchable_id: g3_entry_ids)
        .distinct.count(:commitment_id)
      puts "  With Gazette Part III match: #{with_g3}"
    end

    # With departmental news
    dept_feeds = Feed.where("title ILIKE ANY(ARRAY[?])", [
      "%News Releases%", "%Press Releases%"
    ])
    dept_entry_ids = Entry.where(feed: dept_feeds).pluck(:id)
    with_dept = CommitmentMatch.where(matchable_type: "Entry", matchable_id: dept_entry_ids)
      .distinct.count(:commitment_id)
    puts "  With departmental news match: #{with_dept}"

    # Criteria assessment coverage
    puts "\nCriteria Assessment:"
    total_criteria = Criterion.count
    assessed = Criterion.where.not(status: :not_assessed).count
    puts "  Total criteria: #{total_criteria}"
    puts "  Assessed: #{assessed} (#{(assessed.to_f / total_criteria * 100).round(1)}%)"
    puts "  Unassessed: #{total_criteria - assessed}"

    # Evidence hierarchy violations
    puts "\nEvidence Hierarchy Check:"
    completed = Commitment.completed
    completed.find_each do |c|
      bill_matches = c.commitment_matches.where(matchable_type: "Bill")
      entry_matches = c.commitment_matches.where(matchable_type: "Entry")

      has_royal_assent = bill_matches.any? do |m|
        m.matchable.received_royal_assent_at.present?
      end

      gazette_entry_ids = []
      gazette_entry_ids += g2_entry_ids if gazette_ii_feed
      gazette_entry_ids += g3_entry_ids if gazette_iii_feed

      has_gazette = entry_matches.where(matchable_id: gazette_entry_ids).exists? if gazette_entry_ids.any?

      has_dept_news = entry_matches.where(matchable_id: dept_entry_ids).exists? if dept_entry_ids.any?

      unless has_royal_assent || has_gazette || has_dept_news
        puts "  WARNING: Commitment ##{c.id} '#{c.title.truncate(60)}' marked completed without strong evidence"
      end
    end

    puts "=" * 70
  end

  desc "Full pipeline: fix gaps, reassess, rederive (run sequentially as jobs complete)"
  task full_pipeline: :environment do
    puts "Step 1: Fixing matching gaps..."
    Rake::Task["matching:all_gaps"].invoke

    puts "\nJobs are enqueued. The full pipeline is:"
    puts "  1. rake matching:all_gaps        (done — jobs running)"
    puts "  2. rake matching:reassess         (run after gap jobs finish)"
    puts "  3. rake matching:status_report    (run after assessment jobs finish)"
  end
end
