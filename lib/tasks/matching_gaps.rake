namespace :matching do
  desc "Report on the five data gaps in commitment matching"
  task gap_analysis: :environment do
    puts "=" * 70
    puts "COMMITMENT MATCHING GAP ANALYSIS"
    puts "=" * 70

    # Gap 1: Bill C-15 matches
    c15 = Bill.find_by("bill_number_formatted ILIKE ?", "%C-15%")
    if c15
      c15_matches = CommitmentMatch.where(matchable: c15).count
      budget_commitments = CommitmentSource.joins(:source)
        .where(sources: { source_type: :budget }).distinct.count(:commitment_id)
      puts "\nGap 1: Bill C-15 (Budget Implementation Act)"
      puts "  Bill found: #{c15.bill_number_formatted} — #{c15.short_title}"
      puts "  Royal Assent: #{c15.received_royal_assent_at&.to_date || 'NOT YET'}"
      puts "  Commitment matches: #{c15_matches}"
      puts "  Budget-sourced commitments: #{budget_commitments}"
      puts "  STATUS: #{c15_matches.zero? ? 'GAP — ZERO MATCHES' : 'OK'}"
    else
      puts "\nGap 1: Bill C-15 — NOT FOUND in bills table"
    end

    # Gap 1b: Other key government bills
    %w[C-12 C-14 C-20].each do |bill_num|
      bill = Bill.find_by("bill_number_formatted ILIKE ?", "%#{bill_num}%")
      next unless bill

      matches = CommitmentMatch.where(matchable: bill).count
      puts "  #{bill.bill_number_formatted}: #{matches} matches (Royal Assent: #{bill.received_royal_assent_at&.to_date || 'no'})"
    end

    # Gap 2: Departmental feeds with zero matches
    puts "\nGap 2: Departmental Feed Matching"
    departmental_keywords = %w[
      Defence IRCC Indigenous Innovation ISED
      Global\ Affairs Health Environment ESDC
      Transport Natural\ Resources Treasury CIRNAC
      Employment Finance
    ]

    Feed.find_each do |feed|
      entry_ids = feed.entries.where(skipped_at: nil, is_index: [ false, nil ]).pluck(:id)
      next if entry_ids.empty?

      matched = CommitmentMatch.where(matchable_type: "Entry", matchable_id: entry_ids).count
      total = entry_ids.size
      pct = total.positive? ? (matched.to_f / total * 100).round(1) : 0
      flag = matched.zero? ? " *** GAP ***" : ""
      puts "  #{feed.title}: #{matched}/#{total} entries matched (#{pct}%)#{flag}"
    end

    # Gap 3: Gazette Part II
    puts "\nGap 3: Canada Gazette Part II"
    gazette_ii_feed = Feed.find_by("title ILIKE ?", "%Gazette Part II%")
    if gazette_ii_feed
      total_ii = gazette_ii_feed.entries.where(skipped_at: nil, is_index: [ false, nil ]).count
      matched_ii_ids = gazette_ii_feed.entries.where(skipped_at: nil, is_index: [ false, nil ]).pluck(:id)
      matched_ii = CommitmentMatch.where(matchable_type: "Entry", matchable_id: matched_ii_ids).distinct.count(:matchable_id)
      puts "  Total content entries: #{total_ii}"
      puts "  Entries with matches: #{matched_ii}"
      puts "  Unmatched: #{total_ii - matched_ii}"
    else
      puts "  Feed not found!"
    end

    # Gap 4: Gazette Part III
    puts "\nGap 4: Canada Gazette Part III"
    gazette_iii_feed = Feed.find_by("title ILIKE ?", "%Gazette Part III%")
    if gazette_iii_feed
      total_iii = gazette_iii_feed.entries.where(skipped_at: nil, is_index: [ false, nil ]).count
      matched_iii_ids = gazette_iii_feed.entries.where(skipped_at: nil, is_index: [ false, nil ]).pluck(:id)
      matched_iii = CommitmentMatch.where(matchable_type: "Entry", matchable_id: matched_iii_ids).distinct.count(:matchable_id)
      puts "  Total content entries: #{total_iii}"
      puts "  Entries with matches: #{matched_iii}"
      puts "  STATUS: #{matched_iii.zero? ? 'GAP — ZERO MATCHES' : "#{matched_iii} matched"}"
    else
      puts "  Feed not found!"
    end

    # Gap 5: Finance statements
    puts "\nGap 5: Finance Department Statements"
    finance_feeds = Feed.where("title ILIKE ?", "%Finance%")
    finance_feeds.each do |feed|
      entry_ids = feed.entries.where(skipped_at: nil, is_index: [ false, nil ]).pluck(:id)
      matched = CommitmentMatch.where(matchable_type: "Entry", matchable_id: entry_ids).count
      puts "  #{feed.title}: #{matched}/#{entry_ids.size} entries matched"
    end

    # Overall summary
    puts "\n" + "=" * 70
    puts "OVERALL MATCHING SUMMARY"
    total_matches = CommitmentMatch.count
    bill_matches = CommitmentMatch.where(matchable_type: "Bill").count
    entry_matches = CommitmentMatch.where(matchable_type: "Entry").count
    statcan_matches = CommitmentMatch.where(matchable_type: "StatcanDataset").count
    commitments_with_matches = CommitmentMatch.distinct.count(:commitment_id)
    total_commitments = Commitment.count

    puts "  Total matches: #{total_matches}"
    puts "    Bill matches: #{bill_matches}"
    puts "    Entry matches: #{entry_matches}"
    puts "    StatCan matches: #{statcan_matches}"
    puts "  Commitments with matches: #{commitments_with_matches}/#{total_commitments}"
    puts "  Commitments with NO matches: #{total_commitments - commitments_with_matches}"
    puts "=" * 70
  end

  desc "Gap 1: Match Bill C-15 and other key government bills to commitments"
  task bill_c15: :environment do
    bill_numbers = %w[C-15 C-12 C-14 C-20]
    count = 0

    bill_numbers.each do |num|
      bill = Bill.find_by("bill_number_formatted ILIKE ?", "%#{num}%")
      unless bill
        puts "Bill #{num} not found, skipping"
        next
      end

      unless bill.government_bill?
        puts "Bill #{num} is not a government bill, skipping"
        next
      end

      existing = CommitmentMatch.where(matchable: bill).count
      puts "Enqueuing #{bill.bill_number_formatted} (#{bill.short_title}) — #{existing} existing matches"
      CommitmentRelevanceFilterJob.perform_later(bill)
      count += 1
    end

    puts "Enqueued matching for #{count} key government bills"
  end

  desc "Gap 2: Match all departmental news feed entries that have no commitment matches"
  task departmental_feeds: :environment do
    # Find all departmental news feeds (not Gazette, not PM, not backgrounders/speeches/statements)
    departmental_feed_titles = [
      "National Defence",
      "Immigration, Refugees and Citizenship",
      "Indigenous Services",
      "Innovation, Science and Economic Development",
      "Global Affairs",
      "Health Canada",
      "Environment and Climate Change",
      "Employment and Social Development",
      "Transport Canada",
      "Natural Resources",
      "Treasury Board",
      "Crown-Indigenous Relations",
      "Department of Finance",
      "Parliamentary Budget Officer",
      "Prime Minister"
    ]

    count = 0
    feeds_processed = 0

    Feed.find_each do |feed|
      next unless departmental_feed_titles.any? { |t| feed.title&.include?(t) }

      feeds_processed += 1
      entries = feed.entries.where(skipped_at: nil, is_index: [ false, nil ])
        .where.not(scraped_at: nil)

      # Only process entries that have no existing commitment matches
      entries.left_joins(:commitment_matches)
        .where(commitment_matches: { id: nil })
        .find_each do |entry|
          CommitmentRelevanceFilterJob.perform_later(entry)
          count += 1
        end

      puts "  #{feed.title}: enqueued unmatched entries"
    end

    puts "Enqueued #{count} unmatched entries from #{feeds_processed} departmental feeds"
  end

  desc "Gap 3: Re-match all Gazette Part II entries against commitments"
  task gazette_part_ii: :environment do
    feed = Feed.find_by("title ILIKE ?", "%Gazette Part II%")
    unless feed
      puts "Gazette Part II feed not found!"
      return
    end

    count = 0
    entries = feed.entries.where(skipped_at: nil, is_index: [ false, nil ])
      .where.not(scraped_at: nil)

    # Process entries that have no existing commitment matches
    entries.left_joins(:commitment_matches)
      .where(commitment_matches: { id: nil })
      .find_each do |entry|
        CommitmentRelevanceFilterJob.perform_later(entry)
        count += 1
      end

    puts "Enqueued #{count} unmatched Gazette Part II entries for matching"
  end

  desc "Gap 4: Match all Gazette Part III entries against commitments"
  task gazette_part_iii: :environment do
    feed = Feed.find_by("title ILIKE ?", "%Gazette Part III%")
    unless feed
      puts "Gazette Part III feed not found!"
      return
    end

    count = 0
    # For Gazette Part III (Acts of Parliament), re-match ALL entries since there are few
    feed.entries.where(skipped_at: nil, is_index: [ false, nil ])
      .where.not(scraped_at: nil)
      .find_each do |entry|
        CommitmentRelevanceFilterJob.perform_later(entry)
        count += 1
      end

    puts "Enqueued #{count} Gazette Part III entries for matching"
  end

  desc "Gap 5: Match Finance department statements against commitments"
  task finance_statements: :environment do
    feeds = Feed.where("title ILIKE ?", "%Finance%")
    count = 0

    feeds.each do |feed|
      feed.entries.where(skipped_at: nil, is_index: [ false, nil ])
        .where.not(scraped_at: nil)
        .left_joins(:commitment_matches)
        .where(commitment_matches: { id: nil })
        .find_each do |entry|
          CommitmentRelevanceFilterJob.perform_later(entry)
          count += 1
        end

      puts "  #{feed.title}: enqueued unmatched entries"
    end

    puts "Enqueued #{count} unmatched Finance entries for matching"
  end

  desc "Fetch data for entries that haven't been scraped yet (prerequisite for matching)"
  task fetch_unscraped: :environment do
    count = 0
    Entry.where(scraped_at: nil, skipped_at: nil)
      .where.not(url: nil)
      .find_each do |entry|
        EntryDataFetcherJob.perform_later(entry)
        count += 1
      end

    puts "Enqueued #{count} unscraped entries for data fetching"
    puts "After fetching completes, run: rake matching:all_gaps"
  end

  desc "Fix all five matching gaps (enqueues jobs for gaps 1-5)"
  task all_gaps: :environment do
    puts "=== Gap 1: Key Government Bills ==="
    Rake::Task["matching:bill_c15"].invoke

    puts "\n=== Gap 2: Departmental News Feeds ==="
    Rake::Task["matching:departmental_feeds"].invoke

    puts "\n=== Gap 3: Gazette Part II ==="
    Rake::Task["matching:gazette_part_ii"].invoke

    puts "\n=== Gap 4: Gazette Part III ==="
    Rake::Task["matching:gazette_part_iii"].invoke

    puts "\n=== Gap 5: Finance Statements ==="
    Rake::Task["matching:finance_statements"].invoke

    puts "\n" + "=" * 70
    puts "All gap-filling jobs enqueued."
    puts "After jobs complete, run: rake matching:reassess"
    puts "=" * 70
  end

  desc "Also match all unmatched scraped entries regardless of feed (broad catch-all)"
  task unmatched_entries: :environment do
    count = 0
    Entry.where(skipped_at: nil, is_index: [ false, nil ])
      .where.not(scraped_at: nil)
      .left_joins(:commitment_matches)
      .where(commitment_matches: { id: nil })
      .find_each do |entry|
        CommitmentRelevanceFilterJob.perform_later(entry)
        count += 1
      end

    puts "Enqueued #{count} unmatched entries for matching"
  end

  desc "Match all unmatched government bills"
  task unmatched_bills: :environment do
    count = 0
    Bill.government_bills
      .left_joins(:commitment_matches)
      .where(commitment_matches: { id: nil })
      .find_each do |bill|
        CommitmentRelevanceFilterJob.perform_later(bill)
        count += 1
      end

    puts "Enqueued #{count} unmatched government bills for matching"
  end
end
