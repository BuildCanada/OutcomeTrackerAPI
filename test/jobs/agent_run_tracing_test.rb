require "test_helper"
require "rbconfig"
require "timeout"

class AgentRunTracingTest < ActiveSupport::TestCase
  setup do
    @original_env = ENV.to_h.slice("CLAUDE_CODE_OAUTH_TOKENS", "CLAUDE_CODE_OAUTH_TOKEN", "ANTHROPIC_API_KEY", "RAILS_MASTER_KEY", "SECRET_KEY_BASE")
    @original_env.each_key { |key| ENV.delete(key) }
    @job = AgentEvaluateCommitmentJob.new
    @job.define_singleton_method(:agent_api_key) { "secret-api-key" }
    @job.define_singleton_method(:system_prompt) { "Auth secret-api-key" }
  end

  teardown do
    %w[CLAUDE_CODE_OAUTH_TOKENS CLAUDE_CODE_OAUTH_TOKEN ANTHROPIC_API_KEY RAILS_MASTER_KEY SECRET_KEY_BASE].each { |key| ENV.delete(key) }
    @original_env.each { |key, value| ENV[key] = value }
  end

  def run_script(script)
    @job.stub(:build_cmd, [ RbConfig.ruby, "-e", script, "--", "--system-prompt", "Auth secret-api-key" ]) do
      @job.send(:run_agent, "Evaluate secret-api-key", hook_script: "unused")
    end
  end

  test "records ordered stdout events and separate stderr with redacted secrets" do
    script = <<~'CODE'
      require "json"
      STDOUT.sync = true
      puts({type: "system", session_id: "session-1"}.to_json)
      puts({type: "assistant", message: {content: [{type: "tool_use", input: {command: "curl secret-api-key"}}]}}.to_json)
      STDERR.puts "warning secret-api-key"
      puts({type: "result", result: "done"}.to_json)
    CODE
    stdout, stderr = capture_subprocess_io { assert run_script(script).success? }
    assert_empty stdout
    assert_empty stderr
    run = AgentRun.order(:id).last
    assert_equal "succeeded", run.status
    assert_equal "session-1", run.session_id
    assert_equal @job.job_id, run.active_job_id
    assert_equal "Evaluate [REDACTED]", run.prompt
    assert_equal "Auth [REDACTED]", run.system_prompt
    assert_equal [ 1, 2, 3, 4 ], run.events.pluck(:sequence)
    assert_equal %w[system assistant result], run.events.where(stream: "stdout").map { |event| event.payload["type"] }
    assert_equal "warning [REDACTED]\n", run.events.find_by!(stream: "stderr").payload["text"]
    refute_includes run.events.map(&:payload).to_json, "secret-api-key"
    assert run.finished_at
  end

  test "nonzero exit retains partial output and each attempt gets a separate run" do
    2.times { refute run_script('puts %q({"type":"assistant","message":"partial"}); exit 7').success? }
    runs = AgentRun.where(active_job_id: @job.job_id)
    assert_equal 2, runs.count
    runs.each do |run|
      assert_equal "failed", run.status
      assert_equal 7, run.exit_code
      assert_equal "partial", run.events.first.payload["message"]
    end
  end

  test "malformed and unterminated output is preserved" do
    assert run_script('STDOUT.write "not json secret-api-key"').success?
    assert_equal({ "type" => "unparsed_stdout", "text" => "not json [REDACTED]" }, AgentRun.order(:id).last.events.first.payload)
  end

  test "persistence failure terminates child and retains previous events" do
    create_run = AgentRun.method(:create!)
    AgentRun.stub(:create!, ->(**attributes) {
      run = create_run.call(**attributes)
      events = run.events
      create_event = events.method(:create!)
      events.define_singleton_method(:create!) do |**event_attributes|
        raise "recording secret-api-key" if event_attributes[:sequence] == 2
        create_event.call(**event_attributes)
      end
      run
    }) do
      Timeout.timeout(5) do
        error = assert_raises(RuntimeError) do
          run_script('STDOUT.sync = true; 2.times { puts %q({"type":"assistant"}) }; sleep 60')
        end
        assert_equal "recording secret-api-key", error.message
      end
    end
    run = AgentRun.order(:id).last
    assert_equal "failed", run.status
    assert_equal 1, run.events.count
    assert_equal "RuntimeError: recording [REDACTED]", run.error_message
  end

  test "unicode survives chunks and stderr is valid JSON" do
    script = <<~'CODE'
      text = "évidence 🦫".bytes
      [STDOUT, STDERR].each do |io|
        io.sync = true
        text.each { |byte| io.write(byte.chr); sleep 0.001 }
      end
    CODE
    assert run_script(script).success?
    assert_equal [ "évidence 🦫", "évidence 🦫" ], AgentRun.order(:id).last.events.map { |event| event.payload["text"] }
  end

  test "CLI result errors are reflected even when the process exits zero" do
    assert_raises(RunsClaudeAgent::AgentExecutionError) do
      run_script('puts %q({"type":"result","is_error":true})')
    end
    assert_equal "failed", AgentRun.order(:id).last.status
  end

  test "each attempt selects a credential and isolates child secrets" do
    ENV["CLAUDE_CODE_OAUTH_TOKENS"] = { "one" => "oauth-one", "two" => "oauth-two" }.to_json
    ENV["CLAUDE_CODE_OAUTH_TOKEN"] = "fallback-secret"
    ENV["ANTHROPIC_API_KEY"] = "anthropic-secret"
    ENV["RAILS_MASTER_KEY"] = "rails-secret"
    ENV["SECRET_KEY_BASE"] = "base-secret"
    script = <<~'CODE'
      require "json"
      token = ENV.fetch("CLAUDE_CODE_OAUTH_TOKEN")
      puts({type: "result", selected: token == "oauth-one" ? "one" : "two",
        secrets: "oauth-one oauth-two fallback-secret secret-api-key anthropic-secret",
        leaked_env: ENV.keys & %w[CLAUDE_CODE_OAUTH_TOKENS ANTHROPIC_API_KEY RAILS_MASTER_KEY SECRET_KEY_BASE]}.to_json)
    CODE
    ClaudeOauthPool.credentials.each do |credential|
      ClaudeOauthPool.stub(:pick, credential) { assert run_script(script).success? }
      run = AgentRun.order(:id).last
      assert_equal credential.label, run.oauth_token_label
      assert_equal credential.fingerprint, run.oauth_token_fingerprint
      assert_equal credential.label, run.events.last.payload["selected"]
      assert_empty run.events.last.payload["leaked_env"]
      assert_equal ([ "[REDACTED]" ] * 5).join(" "), run.events.last.payload["secrets"]
    end
  end

  test "cleanup cascades to old events and keeps the exact retention boundary" do
    travel_to Time.current.change(usec: 0) do
      run_script('puts %q({"type":"result"})')
      old = AgentRun.order(:id).last
      old.update!(started_at: 60.days.ago - 1.second)
      run_script('puts %q({"type":"result"})')
      boundary = AgentRun.order(:id).last
      boundary.update!(started_at: 60.days.ago)
      AgentRunCleanupJob.perform_now
      refute AgentRun.exists?(old.id)
      refute AgentRunEvent.exists?(agent_run_id: old.id)
      assert AgentRun.exists?(boundary.id)
      assert AgentRunEvent.exists?(agent_run_id: boundary.id)
    end
  end
end
