module Api
  class BurndownController < ApplicationController
    STARTED_STATUSES = %w[in_progress completed broken].freeze
    COMPLETED_STATUSES = %w[completed].freeze
    ABANDONED_STATUSES = %w[broken].freeze

    def show
      government = Government.find(params[:government_id])
      commitments = government.commitments

      if params[:source_type].present?
        commitments = commitments.joins(:sources).where(sources: { source_type: params[:source_type] }).distinct
      end

      policy_area = nil
      if params[:policy_area_slug].present?
        policy_area = PolicyArea.find_by!(slug: params[:policy_area_slug])
        commitments = commitments.where(policy_area: policy_area)
      end

      department = nil
      if params[:department_slug].present?
        department = Department.find_by!(slug: params[:department_slug])
        commitments = commitments.joins(:lead_commitment_department).where(commitment_departments: { department_id: department.id })
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

      # Gather all real-world evidence dates per commitment
      # (from CommitmentMatch → Bill/StatcanDataset and from CriterionAssessment → Source)
      all_evidence_dates = evidence_dates_for(commitment_ids)

      # Build sorted events, tracking effective state per commitment
      # to avoid double-counting from duplicate status change records
      events = []
      effective_state = {}

      commitment_records.each do |c|
        initial = first_change_by_commitment[c.id] || c.status
        effective_state[c.id] = initial
        scope_date = c.date_promised || c.created_at.to_date

        # Scope always enters on date_promised
        events << { date: scope_date, delta_scope: 1, delta_started: 0, delta_completed: 0, delta_broken: 0 }

        # Add initial state event for all commitments that start in a non-default state
        if STARTED_STATUSES.include?(initial)
          evidence_date = all_evidence_dates[c.id]&.min || scope_date
          events << { date: evidence_date, delta_scope: 0, delta_started: 1,
                      delta_completed: COMPLETED_STATUSES.include?(initial) ? 1 : 0,
                      delta_broken: ABANDONED_STATUSES.include?(initial) ? 1 : 0 }
        end
      end

      status_changes.each do |sc|
        # Use effective state to calculate deltas, skipping duplicate transitions
        current = effective_state[sc.commitment_id]
        next if sc.new_status == current

        was_started = STARTED_STATUSES.include?(current)
        now_started = STARTED_STATUSES.include?(sc.new_status)
        ds = 0
        ds = 1 if now_started && !was_started
        ds = -1 if !now_started && was_started

        was_completed = COMPLETED_STATUSES.include?(current)
        now_completed = COMPLETED_STATUSES.include?(sc.new_status)
        dc = 0
        dc = 1 if now_completed && !was_completed
        dc = -1 if !now_completed && was_completed

        was_broken = ABANDONED_STATUSES.include?(current)
        now_broken = ABANDONED_STATUSES.include?(sc.new_status)
        da = 0
        da = 1 if now_broken && !was_broken
        da = -1 if !now_broken && was_broken

        # Use the latest real-world evidence date before the job ran,
        # falling back to the job run date if no evidence dates exist
        job_date = sc.changed_at.to_date
        dates = all_evidence_dates[sc.commitment_id] || []
        event_date = dates.select { |d| d <= job_date }.max || dates.min || job_date

        events << { date: event_date, delta_scope: 0,
                    delta_started: ds, delta_completed: dc, delta_broken: da }

        effective_state[sc.commitment_id] = sc.new_status
      end

      events.sort_by! { |e| e[:date] }

      # Aggregate into daily series
      scope = 0
      started = 0
      completed = 0
      broken = 0
      series = []
      current_date = nil

      events.each do |e|
        if current_date && e[:date] != current_date
          series << { date: current_date.iso8601, scope: scope, started: started, completed: completed, broken: broken }
        end
        current_date = e[:date]
        scope += e[:delta_scope]
        started += e[:delta_started]
        completed += e[:delta_completed]
        broken += e[:delta_broken]
      end

      series << { date: current_date.iso8601, scope: scope, started: started, completed: completed, broken: broken } if current_date

      # Also emit today if last event was before today
      if current_date && current_date < Date.current
        series << { date: Date.current.iso8601, scope: scope, started: started, completed: completed, broken: broken }
      end

      render json: {
        government: { id: government.id, name: government.name },
        mandate_start: mandate_start&.iso8601,
        mandate_end: mandate_end&.iso8601,
        total_commitments: commitments.count,
        policy_area: policy_area ? { id: policy_area.id, name: policy_area.name, slug: policy_area.slug } : nil,
        department: department ? { id: department.id, display_name: department.display_name, slug: department.slug } : nil,
        series: series
      }
    end

    private

    def evidence_dates_for(commitment_ids)
      result = Hash.new { |h, k| h[k] = [] }

      # Real-world dates from matched evidence (Bills, StatcanDatasets)
      CommitmentMatch.where(commitment_id: commitment_ids).includes(:matchable).each do |cm|
        date = evidence_date_for(cm.matchable)
        result[cm.commitment_id] << date if date
      end

      # Real-world dates from criterion assessment sources
      CriterionAssessment
        .joins(criterion: :commitment)
        .joins("LEFT JOIN sources ON sources.id = criterion_assessments.source_id")
        .where(criteria: { commitment_id: commitment_ids })
        .where.not(sources: { date: nil })
        .pluck("criteria.commitment_id", "sources.date")
        .each do |cid, date|
          result[cid] << date
        end

      # Deduplicate
      result.each_value(&:uniq!)
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
      when Entry
        matchable.published_at&.to_date
      end
    end
  end
end
