module Api
  class BurndownController < ApplicationController
    def show
      government = Government.find(params[:government_id])
      commitments = government.commitments

      start_date = (params[:start_date]&.to_date || commitments.minimum(:created_at)&.to_date || Date.current)
      end_date = (params[:end_date]&.to_date || Date.current)

      status_changes = CommitmentStatusChange
        .joins(:commitment)
        .where(commitments: { government_id: government.id })
        .where(changed_at: start_date.beginning_of_day..end_date.end_of_day)
        .order(:changed_at)

      commitment_dates = commitments.group("DATE(created_at)").count

      render json: {
        government: { id: government.id, name: government.name },
        total_commitments: commitments.count,
        current_status_counts: commitments.group(:status).count,
        commitments_added_by_date: commitment_dates,
        status_changes: status_changes.map { |sc|
          {
            commitment_id: sc.commitment_id,
            previous_status: sc.previous_status,
            new_status: sc.new_status,
            changed_at: sc.changed_at.iso8601
          }
        },
        date_range: { start_date: start_date.iso8601, end_date: end_date.iso8601 }
      }
    end
  end
end
