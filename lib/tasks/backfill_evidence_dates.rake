namespace :backfill do
  desc "Backfill all date fields to use real-world evidence dates instead of job-run dates"
  task evidence_dates: :environment do
    puts "=== B1: Backfill CommitmentMatch.matched_at ==="
    backfill_matched_at

    puts "\n=== B2: Backfill CriterionAssessment.assessed_at and Criterion.assessed_at ==="
    backfill_assessed_at

    puts "\n=== B3: Backfill CommitmentStatusChange.changed_at ==="
    backfill_changed_at

    puts "\n=== B4: Backfill FeedItem.occurred_at ==="
    backfill_feed_items

    puts "\n=== B5: Backfill Commitment.last_assessed_at ==="
    backfill_last_assessed_at

    puts "\nDone!"
  end
end

def evidence_date_for(matchable)
  case matchable
  when Entry then matchable.published_at
  when Bill then [ matchable.passed_house_first_reading_at, matchable.latest_activity_at ].compact.max
  when StatcanDataset then matchable.last_synced_at
  end
end

def backfill_matched_at
  updated = 0
  CommitmentMatch.includes(:matchable).find_each do |cm|
    date = evidence_date_for(cm.matchable)
    next unless date

    cm.update_column(:matched_at, date)
    updated += 1
  end
  puts "Updated #{updated} commitment matches"
end

def backfill_assessed_at
  assessments_updated = 0
  criteria_updated = 0

  Commitment.joins(:commitment_matches).distinct.find_each do |commitment|
    latest_date = commitment.commitment_matches
      .includes(:matchable)
      .filter_map { |cm| evidence_date_for(cm.matchable) }
      .max
    next unless latest_date

    commitment.criteria.find_each do |criterion|
      count = criterion.criterion_assessments.where.not(assessed_at: latest_date).update_all(assessed_at: latest_date)
      assessments_updated += count

      if criterion.assessed_at.present? && criterion.assessed_at != latest_date
        criterion.update_column(:assessed_at, latest_date)
        criteria_updated += 1
      end
    end
  end
  puts "Updated #{assessments_updated} criterion assessments, #{criteria_updated} criteria"
end

def backfill_changed_at
  updated = 0
  CommitmentStatusChange.includes(commitment: { commitment_matches: :matchable }).find_each do |sc|
    latest_date = sc.commitment.commitment_matches
      .filter_map { |cm| evidence_date_for(cm.matchable) }
      .max
    next unless latest_date

    sc.update_column(:changed_at, latest_date)
    updated += 1
  end
  puts "Updated #{updated} status changes"
end

def backfill_feed_items
  updated = 0

  # Update FeedItems linked to status changes
  FeedItem.where(feedable_type: "CommitmentStatusChange").includes(:feedable).find_each do |fi|
    next unless fi.feedable
    next if fi.occurred_at == fi.feedable.changed_at

    fi.update_column(:occurred_at, fi.feedable.changed_at)
    updated += 1
  end

  # Update FeedItems linked to criterion assessments
  FeedItem.where(feedable_type: "CriterionAssessment").includes(:feedable).find_each do |fi|
    next unless fi.feedable
    next if fi.occurred_at == fi.feedable.assessed_at

    fi.update_column(:occurred_at, fi.feedable.assessed_at)
    updated += 1
  end

  puts "Updated #{updated} feed items"
end

def backfill_last_assessed_at
  updated = 0
  Commitment.joins(:commitment_matches).distinct.find_each do |commitment|
    latest_date = commitment.commitment_matches
      .includes(:matchable)
      .filter_map { |cm| evidence_date_for(cm.matchable) }
      .max
    next unless latest_date

    commitment.update_column(:last_assessed_at, latest_date)
    updated += 1
  end
  puts "Updated #{updated} commitments"
end
