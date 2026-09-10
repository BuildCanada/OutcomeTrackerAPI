require "net/http"
require "open3"

# Shared plumbing for jobs that shell out to the Claude Code CLI as an agent.
#
# The agent talks back to this app over HTTP using RAILS_API_URL / RAILS_API_KEY.
# If either is misconfigured the CLI still exits 0 after explaining it is blocked,
# so `preflight_agent_api!` verifies the connection before spending an agent run.
module RunsClaudeAgent
  extend ActiveSupport::Concern

  class ConfigurationError < StandardError; end
  class ApiUnreachableError < StandardError; end

  ALLOWED_TOOLS = [
    "Bash(curl *)",
    "WebFetch(https://*.canada.ca/*)",
    "WebFetch(https://*.gc.ca/*)",
    "WebFetch(https://www.parl.ca/*)",
    "WebSearch"
  ].freeze

  PREFLIGHT_TIMEOUT_SECONDS = 5

  private

  def agent_dir
    Rails.root.join("agent")
  end

  def agent_api_url
    ENV.fetch("RAILS_API_URL", "http://localhost:3000")
  end

  def agent_api_key
    Rails.application.credentials.dig(:agent, :api_key) || ENV["AGENT_API_KEY"]
  end

  def agent_model
    ENV.fetch("AGENT_MODEL", "claude-sonnet-5")
  end

  # Raises if the agent could not possibly succeed: no API key, or the API host
  # (the web service, when running in a separate worker container) is down.
  def preflight_agent_api!
    if agent_api_key.blank?
      raise ConfigurationError, "Agent API key is not set (credentials.agent.api_key or AGENT_API_KEY)"
    end

    uri = URI.join(agent_api_url, "/up")
    response = Net::HTTP.start(uri.host, uri.port,
                               use_ssl: uri.scheme == "https",
                               open_timeout: PREFLIGHT_TIMEOUT_SECONDS,
                               read_timeout: PREFLIGHT_TIMEOUT_SECONDS) do |http|
      http.get(uri.path)
    end

    unless response.is_a?(Net::HTTPSuccess)
      raise ApiUnreachableError, "Rails API at #{agent_api_url} returned #{response.code} from /up"
    end
  rescue SystemCallError, SocketError, Net::OpenTimeout, Net::ReadTimeout, IOError, OpenSSL::SSL::SSLError => e
    raise ApiUnreachableError, "Rails API at #{agent_api_url} is unreachable: #{e.class}: #{e.message}"
  end

  def run_agent(prompt, hook_script:, commitment_id: nil, entry_id: nil)
    stream_agent(
      agent_env(commitment_id: commitment_id, entry_id: entry_id),
      build_cmd(prompt, hook_script: hook_script),
      chdir: agent_dir.to_s
    )
  end

  def stream_agent(env, cmd, chdir:)
    Open3.popen2e(env, *cmd, chdir: chdir) do |stdin, output, thread|
      stdin.close
      output.each_line do |line|
        STDERR.print(line)
        STDERR.flush
      end
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
      "--allowedTools", ALLOWED_TOOLS.join(","),
      "--permission-mode", "bypassPermissions",
      "--model", agent_model,
      "--output-format", "text",
      "--settings", hook_settings
    ]
  end

  def system_prompt
    AgentPrompts::SYSTEM_PROMPT + api_context
  end

  def api_context
    "\n\n## Rails API Connection\nBase URL: `#{agent_api_url}`\nAuth header: `Authorization: Bearer #{agent_api_key}`\nSee CLAUDE.md for endpoint details and enum values.\n"
  end

  def agent_env(commitment_id: nil, entry_id: nil)
    {
      "PATH"                    => ENV["PATH"],
      "CLAUDE_CODE_OAUTH_TOKEN" => ENV["CLAUDE_CODE_OAUTH_TOKEN"],
      "RAILS_API_URL"           => agent_api_url,
      "RAILS_API_KEY"           => agent_api_key,
      "AGENT_MODEL"             => agent_model,
      "COMMITMENT_ID"           => commitment_id&.to_s,
      "ENTRY_ID"                => entry_id&.to_s,
      # Explicitly unset — subprocess must not access Rails credentials
      "RAILS_MASTER_KEY"        => nil,
      "SECRET_KEY_BASE"         => nil
    }.compact
  end
end
