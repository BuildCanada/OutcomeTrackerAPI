require "open3"

class AgentProcessEntryJob < ApplicationJob
  queue_as :default

  retry_on StandardError, wait: 30.seconds, attempts: 3

  def perform(entry)
    agent_dir = Rails.root.join("agent")
    current_date = Date.today.iso8601
    prompt = format(AgentPrompts::PROCESS_ENTRY_PROMPT, entry_id: entry.id, current_date: current_date)
    hook_script = agent_dir.join(".claude/hooks/on_stop_entry.sh").to_s

    Rails.logger.info("AgentProcessEntryJob: Processing entry #{entry.id} (#{entry.title})")

    exit_status = stream_agent(
      agent_env(entry_id: entry.id),
      build_cmd(prompt, hook_script: hook_script),
      chdir: agent_dir.to_s
    )

    unless exit_status.success?
      raise "Agent processing failed for entry #{entry.id} (exit #{exit_status.exitstatus})"
    end

    Rails.logger.info("AgentProcessEntryJob: Success for entry #{entry.id}")
  end

  private

  def stream_agent(env, cmd, chdir:)
    Open3.popen2e(env, *cmd, chdir: chdir) do |stdin, output, thread|
      stdin.close
      output.each_line { |line| $stderr.print(line) }
      thread.value
    end
  end

  def build_cmd(prompt, hook_script:)
    hook_settings = {
      "hooks" => {
        "Stop" => [ { "hooks" => [ { "type" => "command", "command" => hook_script, "async" => true, "timeout" => 10 } ] } ]
      }
    }.to_json

    [
      "claude", "-p", prompt,
      "--system-prompt", system_prompt,
      "--allowedTools", allowed_tools.join(","),
      "--permission-mode", "bypassPermissions",
      "--model", ENV.fetch("AGENT_MODEL", "claude-opus-4-6"),
      "--output-format", "text",
      "--settings", hook_settings
    ]
  end

  def allowed_tools
    [
      "Bash(curl *)",
      "WebFetch(https://*.canada.ca/*)",
      "WebFetch(https://*.gc.ca/*)",
      "WebFetch(https://www.parl.ca/*)",
      "WebSearch"
    ]
  end

  def system_prompt
    AgentPrompts::SYSTEM_PROMPT + api_context
  end

  def api_context
    url = ENV.fetch("RAILS_API_URL", "http://localhost:3000")
    key = Rails.application.credentials.dig(:agent, :api_key) || ENV["AGENT_API_KEY"]
    "\n\n## Rails API Connection\nBase URL: `#{url}`\nAuth header: `Authorization: Bearer #{key}`\nSee CLAUDE.md for endpoint details and enum values.\n"
  end

  def agent_env(commitment_id: nil, entry_id: nil)
    {
      "CLAUDE_CODE_OAUTH_TOKEN" => ENV["CLAUDE_CODE_OAUTH_TOKEN"],
      "RAILS_API_URL"     => ENV.fetch("RAILS_API_URL", "http://localhost:3000"),
      "RAILS_API_KEY"     => Rails.application.credentials.dig(:agent, :api_key) || ENV["AGENT_API_KEY"],
      "AGENT_MODEL"       => ENV.fetch("AGENT_MODEL", "claude-opus-4-6"),
      "COMMITMENT_ID"        => commitment_id&.to_s,
      "ENTRY_ID"             => entry_id&.to_s,
      # Explicitly unset — subprocess must not access Rails credentials
      "RAILS_MASTER_KEY"     => nil,
      "SECRET_KEY_BASE"      => nil
    }.compact
  end
end
