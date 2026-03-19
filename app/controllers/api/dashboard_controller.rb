module Api
  class DashboardController < ApplicationController
    def at_a_glance
      government = Government.find(params[:government_id])

      base_scope = government.commitments
      if params[:source_type].present?
        base_scope = base_scope.joins(:sources).where(sources: { source_type: params[:source_type] }).distinct
      end

      base_commitment_ids = base_scope.pluck(:id)

      policy_areas = PolicyArea.ordered.includes(commitments: :lead_department).where(commitments: { id: base_commitment_ids }).distinct

      data = policy_areas.map do |pa|
        area_commitments = pa.commitments.where(id: base_commitment_ids)
        {
          id: pa.id,
          name: pa.name,
          slug: pa.slug,
          position: pa.position,
          status_counts: area_commitments.group(:status).count,
          commitments: area_commitments.map do |c|
            {
              id: c.id,
              title: c.title,
              status: c.status,
              commitment_type: c.commitment_type,
              lead_department: c.lead_department&.display_name
            }
          end
        }
      end

      unassigned = Commitment.where(id: base_commitment_ids, policy_area_id: nil)
      if unassigned.any?
        data << {
          id: nil,
          name: "Unassigned",
          slug: "unassigned",
          position: 999,
          status_counts: unassigned.group(:status).count,
          commitments: unassigned.map do |c|
            {
              id: c.id,
              title: c.title,
              status: c.status,
              commitment_type: c.commitment_type,
              lead_department: c.lead_department&.display_name
            }
          end
        }
      end

      all_commitments = Commitment.where(id: base_commitment_ids)
      total = all_commitments.count
      status_counts = all_commitments.group(:status).count

      not_started = status_counts.fetch("not_started", 0)
      completed = status_counts.fetch("completed", 0)
      in_progress = status_counts.fetch("in_progress", 0)

      render json: {
        government: { id: government.id, name: government.name },
        total_commitments: total,
        summary: {
          not_started: { count: not_started, label: "Not Started", subtitle: "no action taken" },
          completed: { count: completed, label: "Completed", subtitle: "of #{total} commitments" },
          in_progress: { count: in_progress, label: "In Progress", subtitle: "action taken" }
        },
        status_counts: status_counts,
        policy_areas: data
      }
    end
  end
end
