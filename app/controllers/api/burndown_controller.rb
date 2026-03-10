module Api
  class BurndownController < ApplicationController
    STARTED_STATUSES = %w[in_progress partially_implemented implemented abandoned superseded].freeze
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
      commitment_records = commitments.select(:id, :status, :created_at)
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

      # Build sorted events
      events = []

      commitment_records.each do |c|
        initial = first_change_by_commitment[c.id] || c.status
        events << { date: c.created_at.to_date, delta_scope: 1,
                    delta_started: STARTED_STATUSES.include?(initial) ? 1 : 0,
                    delta_completed: COMPLETED_STATUSES.include?(initial) ? 1 : 0 }
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
  end
end
