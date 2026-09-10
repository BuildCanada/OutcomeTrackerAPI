class AgentRunCleanupJob < ApplicationJob
  queue_as :default

  def perform
    # The database cascades deletion to events, including abandoned partial runs.
    AgentRun.where("started_at < ?", 60.days.ago).in_batches.delete_all
  end
end
