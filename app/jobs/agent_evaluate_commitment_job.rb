class AgentEvaluateCommitmentJob < ApplicationJob
  include RunsClaudeAgent

  queue_as :default

  # Concurrency is bounded only by the worker's thread count (good_job.max_threads).
  retry_on StandardError, wait: 30.seconds, attempts: 3

  # Each run is a full agent session (~2 minutes). Skip commitments already
  # assessed today unless force: true, so a re-run of the weekly scan or a
  # duplicate manual enqueue doesn't repeat work.
  def perform(commitment, trigger_type: "manual", as_of_date: nil, force: false)
    if !force && assessed_today?(commitment)
      Rails.logger.info("AgentEvaluateCommitmentJob: Skipping commitment #{commitment.id}, already assessed today at #{commitment.last_assessed_at.iso8601} (pass force: true to re-run)")
      return
    end

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

  private

  def assessed_today?(commitment)
    commitment.last_assessed_at.present? && commitment.last_assessed_at.to_date == Date.current
  end
end
