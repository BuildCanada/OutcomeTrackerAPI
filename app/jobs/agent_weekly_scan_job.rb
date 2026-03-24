class AgentWeeklyScanJob < ApplicationJob
  queue_as :default

  def perform(government = nil)
    government ||= Government.first

    commitments = government.commitments.where.not(status: :broken)

    Rails.logger.info("AgentWeeklyScanJob: Starting weekly scan for #{commitments.count} commitments")

    commitments.find_each do |commitment|
      AgentEvaluateCommitmentJob.perform_later(commitment, trigger_type: "weekly_scan")
    end

    Rails.logger.info("AgentWeeklyScanJob: Enqueued #{commitments.count} evaluation jobs")
  end
end
