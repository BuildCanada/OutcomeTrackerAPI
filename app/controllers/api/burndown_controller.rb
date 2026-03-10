module Api
  class BurndownController < ApplicationController
    STARTED_STATUSES = %w[in_progress partially_implemented implemented abandoned].freeze
    COMPLETED_STATUSES = %w[implemented].freeze

    def show
      government = Government.find(params[:government_id])
      commitments = government.commitments

      policy_area = nil
      if params[:policy_area_slug].present?
        policy_area = PolicyArea.find_by!(slug: params[:policy_area_slug])
        commitments = commitments.where(policy_area: policy_area)
      end

      mandate_start = government.mandate_start
      mandate_end = government.mandate_end

      # Build events from commitments and status changes
      commitment_records = commitments.select(:id, :status, :date_promised, :created_at)
      commitment_ids = commitment_records.map(&:id)

      status_changes = CommitmentStatusChange
        .where(commitment_id: commitment_ids)
        .order(:changed_at)

      # Determine initial status for each commitment:
      # If it has status_changes, first change's previous_status is the initial.
      # Otherwise, current status is the initial (it was seeded that way).
      first_change_by_commitment = {}
      status_changes.each do |sc|
        first_change_by_commitment[sc.commitment_id] ||= sc.previous_status
      end

      # For commitments already in a started status without status_change records,
      # use their earliest evidence date instead of date_promised
      earliest_evidence_dates = earliest_evidence_dates_for(commitment_ids)

      # Build sorted events
      events = []

      commitment_records.each do |c|
        initial = first_change_by_commitment[c.id] || c.status
        scope_date = c.date_promised || c.created_at.to_date

        # Scope always enters on date_promised
        events << { date: scope_date, delta_scope: 1, delta_started: 0, delta_completed: 0 }

        # Started/completed enter on evidence date (if no status_change drove it)
        next if first_change_by_commitment.key?(c.id)

        if STARTED_STATUSES.include?(initial)
          evidence_date = earliest_evidence_dates[c.id] || scope_date
          events << { date: evidence_date, delta_scope: 0, delta_started: 1,
                      delta_completed: COMPLETED_STATUSES.include?(initial) ? 1 : 0 }
        end
      end

      status_changes.each do |sc|
        ds = 0
        dc = 0

        was_started = STARTED_STATUSES.include?(sc.previous_status)
        now_started = STARTED_STATUSES.include?(sc.new_status)
        ds = 1 if now_started && !was_started
        ds = -1 if !now_started && was_started

        was_completed = COMPLETED_STATUSES.include?(sc.previous_status)
        now_completed = COMPLETED_STATUSES.include?(sc.new_status)
        dc = 1 if now_completed && !was_completed
        dc = -1 if !now_completed && was_completed

        events << { date: sc.changed_at.to_date, delta_scope: 0,
                    delta_started: ds, delta_completed: dc }
      end

      events.sort_by! { |e| e[:date] }

      # Aggregate into daily series
      scope = 0
      started = 0
      completed = 0
      series = []
      current_date = nil

      events.each do |e|
        if current_date && e[:date] != current_date
          series << { date: current_date.iso8601, scope: scope, started: started, completed: completed }
        end
        current_date = e[:date]
        scope += e[:delta_scope]
        started += e[:delta_started]
        completed += e[:delta_completed]
      end

      series << { date: current_date.iso8601, scope: scope, started: started, completed: completed } if current_date

      # Also emit today if last event was before today
      if current_date && current_date < Date.current
        series << { date: Date.current.iso8601, scope: scope, started: started, completed: completed }
      end

      render json: {
        government: { id: government.id, name: government.name },
        mandate_start: mandate_start&.iso8601,
        mandate_end: mandate_end&.iso8601,
        total_commitments: commitments.count,
        policy_area: policy_area ? { id: policy_area.id, name: policy_area.name, slug: policy_area.slug } : nil,
        series: series
      }
    end

    private

    def earliest_evidence_dates_for(commitment_ids)
      # Find the earliest real-world date from each commitment's matched evidence.
      # For Bills: use the earliest milestone date (first reading, latest_activity, etc.)
      # For StatcanDatasets: use last_synced_at
      matches = CommitmentMatch.where(commitment_id: commitment_ids).includes(:matchable)

      result = {}
      matches.each do |cm|
        date = evidence_date_for(cm.matchable)
        next unless date

        existing = result[cm.commitment_id]
        result[cm.commitment_id] = date if existing.nil? || date < existing
      end

      result
    end

    def evidence_date_for(matchable)
      case matchable
      when Bill
        [
          matchable.passed_house_first_reading_at,
          matchable.latest_activity_at
        ].compact.min&.to_date
      when StatcanDataset
        matchable.last_synced_at&.to_date
      end
    end
  end
end
