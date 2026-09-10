class AgentProcessEntryJob < ApplicationJob
  include RunsClaudeAgent

  queue_as :default

  retry_on StandardError, wait: 30.seconds, attempts: 3

  def perform(entry)
    current_date = Date.today.iso8601
    prompt = format(AgentPrompts::PROCESS_ENTRY_PROMPT, entry_id: entry.id, current_date: current_date)
    hook_script = agent_dir.join(".claude/hooks/on_stop_entry.sh").to_s

    Rails.logger.info("AgentProcessEntryJob: Processing entry #{entry.id} (#{entry.title})")

    preflight_agent_api!

    exit_status = run_agent(prompt, hook_script: hook_script, entry_id: entry.id)

    unless exit_status.success?
      raise "Agent processing failed for entry #{entry.id} (exit #{exit_status.exitstatus})"
    end

    Rails.logger.info("AgentProcessEntryJob: Success for entry #{entry.id}")
  end
end
