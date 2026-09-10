require "test_helper"

class AgentProcessEntryJobTest < ActiveJob::TestCase
  setup do
    @entry = entries(:entry_one)
    @original_url = ENV["RAILS_API_URL"]
    @original_key = ENV["AGENT_API_KEY"]
  end

  teardown do
    ENV["RAILS_API_URL"] = @original_url
    ENV["AGENT_API_KEY"] = @original_key
  end

  test "schedules a retry instead of launching the agent when the Rails API is unreachable" do
    ENV["AGENT_API_KEY"] = "test-key"
    ENV["RAILS_API_URL"] = "http://127.0.0.1:1"

    error = nil
    callback = ->(*, payload) { error = payload[:error] }

    ActiveSupport::Notifications.subscribed(callback, "enqueue_retry.active_job") do
      AgentProcessEntryJob.perform_now(@entry)
    end

    assert_enqueued_jobs 1, only: AgentProcessEntryJob
    assert_instance_of RunsClaudeAgent::ApiUnreachableError, error
  end
end
