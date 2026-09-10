require "test_helper"

class AgentEvaluateCommitmentJobTest < ActiveJob::TestCase
  setup do
    @commitment = commitments(:defence_spending)
    @original_url = ENV["RAILS_API_URL"]
    @original_key = ENV["AGENT_API_KEY"]
  end

  teardown do
    ENV["RAILS_API_URL"] = @original_url
    ENV["AGENT_API_KEY"] = @original_key
  end

  test "schedules a retry instead of launching the agent when no API key is configured" do
    ENV.delete("AGENT_API_KEY")

    Rails.application.credentials.stub(:dig, nil) do
      error = perform_and_capture_retry_error(AgentEvaluateCommitmentJob.new(@commitment))

      assert_instance_of RunsClaudeAgent::ConfigurationError, error
      assert_match(/API key is not set/, error.message)
    end
  end

  test "schedules a retry instead of launching the agent when the Rails API is unreachable" do
    ENV["AGENT_API_KEY"] = "test-key"
    ENV["RAILS_API_URL"] = "http://127.0.0.1:1"

    error = perform_and_capture_retry_error(AgentEvaluateCommitmentJob.new(@commitment))

    assert_instance_of RunsClaudeAgent::ApiUnreachableError, error
    assert_match(%r{http://127\.0\.0\.1:1 is unreachable}, error.message)
  end

  private

  # retry_on rescues the failure and re-enqueues the job; the error is only
  # visible through the enqueue_retry instrumentation event.
  def perform_and_capture_retry_error(job)
    error = nil
    callback = ->(*, payload) { error = payload[:error] }

    ActiveSupport::Notifications.subscribed(callback, "enqueue_retry.active_job") do
      job.perform_now
    end

    assert_enqueued_jobs 1, only: job.class
    error
  end
end
