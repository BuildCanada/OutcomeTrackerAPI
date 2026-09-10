class AgentEvaluateCommitmentJob < ApplicationJob
  include GoodJob::ActiveJobExtensions::Concurrency
  include RunsClaudeAgent

  queue_as :default

  good_job_control_concurrency_with(
    perform_limit: 5,
    enqueue_limit: 550,
    key: "AgentEvaluateCommitmentJob"
  )

  retry_on GoodJob::ActiveJobExtensions::Concurrency::ConcurrencyExceededError, wait: 60.seconds, attempts: Float::INFINITY
  retry_on StandardError, wait: 30.seconds, attempts: 3

  def perform(commitment, trigger_type: "manual", as_of_date: nil)
    current_date = as_of_date || Date.today.iso8601
    prompt = format(AgentPrompts::EVALUATE_COMMITMENT_PROMPT, commitment_id: commitment.id, current_date: current_date)
    hook_script = agent_dir.join(".claude/hooks/on_stop_commitment.sh").to_s

    Rails.logger.info("AgentEvaluateCommitmentJob: Evaluating commitment #{commitment.id} (#{trigger_type})")

    preflight_agent_api!

    exit_status = run_agent(prompt, hook_script: hook_script, commitment_id: commitment.id)

    unless exit_status.success?
      raise "Agent evaluation failed for commitment #{commitment.id} (exit #{exit_status.exitstatus})"
    end

    Rails.logger.info("AgentEvaluateCommitmentJob: Success for commitment #{commitment.id}")
  end
end
