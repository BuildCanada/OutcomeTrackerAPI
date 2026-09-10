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
  class AgentExecutionError < StandardError; end

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
    secrets = (ClaudeOauthPool.secrets + [ agent_api_key, ENV["ANTHROPIC_API_KEY"] ]).compact.reject(&:empty?)
    credential = ClaudeOauthPool.pick
    cmd = build_cmd(prompt, hook_script: hook_script)
    run = AgentRun.create!(
      commitment_id: commitment_id, entry_id: entry_id,
      active_job_id: job_id, provider_job_id: provider_job_id,
      job_class: self.class.name, attempt: executions,
      model: agent_model, prompt: redact_agent_value(prompt, secrets),
      oauth_token_label: credential&.label, oauth_token_fingerprint: credential&.fingerprint,
      system_prompt: redact_agent_value(cmd[cmd.index("--system-prompt") + 1], secrets),
      status: "running", started_at: Time.current
    )
    env = agent_env(commitment_id: commitment_id, entry_id: entry_id)
    if credential
      env["CLAUDE_CODE_OAUTH_TOKEN"] = credential.token
      env["ANTHROPIC_API_KEY"] = nil
    end
    status = stream_agent(env, cmd, chdir: agent_dir.to_s, run: run, secrets: secrets)
    run.update!(status: status.success? && run.status != "failed" ? "succeeded" : "failed",
                exit_code: status.exitstatus, finished_at: Time.current)
    raise AgentExecutionError, "Claude returned an error result" if status.success? && run.status == "failed"
    status
  rescue StandardError => error
    if run&.persisted?
      begin
        run.update!(status: "failed", finished_at: Time.current,
                    error_message: redact_agent_value("#{error.class}: #{error.message}", secrets))
      rescue StandardError
        Rails.logger.error("Could not finalize agent run #{run.id}")
      end
    end
    raise
  end

  def stream_agent(env, cmd, chdir:, run:, secrets:)
    sequence = 0
    Open3.popen3(env, *cmd, chdir: chdir, pgroup: true) do |stdin, stdout, stderr, thread|
      stdin.close
      buffers = { stdout => +"", stderr => +"" }
      record = lambda do |io, line|
        line = line.dup.force_encoding(Encoding::UTF_8).scrub
        payload = if io == stdout
          begin
            JSON.parse(line)
          rescue JSON::ParserError
            { "type" => "unparsed_stdout", "text" => line }
          end
        else
          { "type" => "stderr", "text" => line }
        end
        payload = redact_agent_value(payload, secrets)
        sequence += 1
        run.events.create!(sequence: sequence, stream: io == stdout ? "stdout" : "stderr", payload: payload)
        if io == stdout && payload.is_a?(Hash) && payload["session_id"].present?
          run.update!(session_id: payload["session_id"])
        end
        if io == stdout && payload.is_a?(Hash) && payload["type"] == "result" && payload["is_error"]
          run.update!(status: "failed")
        end
      end

      begin
        until buffers.empty?
          IO.select(buffers.keys).first.each do |io|
            chunk = io.read_nonblock(16_384, exception: false)
            next if chunk == :wait_readable
            if chunk.nil?
              record.call(io, buffers[io]) unless buffers[io].empty?
              buffers.delete(io)
            else
              buffers[io] << chunk
              while (newline = buffers[io].index("\n"))
                record.call(io, buffers[io].slice!(0..newline))
              end
            end
          end
        end
        thread.value
      ensure
        # Open3 waits for its child when leaving the block. Kill the process
        # group on recording errors so a blocked writer cannot hang the job.
        if thread.alive?
          begin
            Process.kill("KILL", -thread.pid)
          rescue Errno::ESRCH
            # The child exited between the liveness check and the signal.
          end
        end
      end
    end
  end

  def redact_agent_value(value, secrets)
    case value
    when Hash
      value.to_h { |key, item| [ redact_agent_value(key, secrets), redact_agent_value(item, secrets) ] }
    when Array
      value.map { |item| redact_agent_value(item, secrets) }
    when String
      secrets.sort_by { |secret| -secret.length }.reduce(value) { |text, secret| text.gsub(secret, "[REDACTED]") }
    else
      value
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
      "--output-format", "stream-json", "--verbose",
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
      "CLAUDE_CODE_OAUTH_TOKENS" => nil,
      "RAILS_API_URL"           => agent_api_url,
      "RAILS_API_KEY"           => agent_api_key,
      "AGENT_MODEL"             => agent_model,
      "COMMITMENT_ID"           => commitment_id&.to_s,
      "ENTRY_ID"                => entry_id&.to_s,
      # Explicitly unset — subprocess must not access Rails credentials
      "RAILS_MASTER_KEY"        => nil,
      "SECRET_KEY_BASE"         => nil
    }
  end
end
