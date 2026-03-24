module Api
  module Agent
    class EvaluationRunsController < BaseController
      def create
        run = EvaluationRun.create!(
          commitment_id: params.require(:commitment_id),
          agent_run_id: params[:agent_run_id],
          trigger_type: params.require(:trigger_type),
          reasoning: params.require(:reasoning),
          previous_status: params[:previous_status],
          new_status: params[:new_status],
          criteria_assessed: params[:criteria_assessed] || 0,
          evidence_found: params[:evidence_found] || 0,
          search_queries: params[:search_queries] || [],
          duration_seconds: params[:duration_seconds],
        )

        # Update the commitment's last_assessed_at timestamp
        run.commitment.update!(last_assessed_at: Time.current)

        render json: { id: run.id }, status: :created
      end
    end
  end
end
