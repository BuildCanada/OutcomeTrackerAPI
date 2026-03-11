module Api
  class DashboardController < ApplicationController
    def at_a_glance
      government = Government.find(params[:government_id])

      policy_areas = PolicyArea.ordered.includes(commitments: :lead_department).where(commitments: { government_id: government.id }).distinct

      data = policy_areas.map do |pa|
        area_commitments = pa.commitments.where(government_id: government.id)
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

      unassigned = government.commitments.where(policy_area_id: nil)
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

      all_commitments = government.commitments
      total = all_commitments.count
      status_counts = all_commitments.group(:status).count

      not_started = status_counts.fetch("not_started", 0)
      implemented = status_counts.fetch("implemented", 0)
      in_progress = status_counts.fetch("in_progress", 0) +
                    status_counts.fetch("partially_implemented", 0)
      successful = all_commitments.joins(:success_criteria).merge(Criterion.where(status: :met)).distinct.count

      render json: {
        government: { id: government.id, name: government.name },
        total_commitments: total,
        summary: {
          not_started: { count: not_started, label: "Not Started", subtitle: "no action taken" },
          completed: { count: implemented, label: "Completed", subtitle: "of #{total} commitments" },
          successful: { count: successful, label: "Successful", subtitle: "meeting success criteria" }
        },
        status_counts: status_counts,
        policy_areas: data
      }
    end
  end
end
