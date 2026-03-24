require "open3"

class AgentEvaluateCommitmentJob < ApplicationJob
  queue_as :default

  # Limit to 5 concurrent agent evaluations to avoid API rate limits
  include GoodJob::ActiveJobExtensions::Concurrency
  good_job_control_concurrency_with(
    perform_limit: 5,
    enqueue_limit: 550,
    key: "AgentEvaluateCommitmentJob"
  )

  retry_on GoodJob::ActiveJobExtensions::Concurrency::ConcurrencyExceededError, wait: 60.seconds, attempts: Float::INFINITY
  retry_on StandardError, wait: 30.seconds, attempts: 3

  def perform(commitment, trigger_type: "manual", as_of_date: nil)
    agent_dir = Rails.root.join("agent")

    args = [
      "python", "-m", "agent.main", "evaluate",
      "--commitment-id", commitment.id.to_s
    ]
    args.push("--as-of", as_of_date) if as_of_date.present?

    env = agent_env

    Rails.logger.info("AgentEvaluateCommitmentJob: Evaluating commitment #{commitment.id} (#{trigger_type})")

    stdout, stderr, status = Open3.capture3(env, *args, chdir: agent_dir.to_s)

    if status.success?
      Rails.logger.info("AgentEvaluateCommitmentJob: Success for commitment #{commitment.id}")
      Rails.logger.debug(stdout) if stdout.present?
    else
      Rails.logger.error("AgentEvaluateCommitmentJob: Failed for commitment #{commitment.id}")
      Rails.logger.error(stderr) if stderr.present?
      raise "Agent evaluation failed for commitment #{commitment.id}: #{stderr.first(500)}"
    end
  end

  private

  def agent_env
    {
      "ANTHROPIC_API_KEY" => Rails.application.credentials.dig(:anthropic, :api_key) || ENV["ANTHROPIC_API_KEY"],
      "AGENT_DATABASE_URL" => agent_database_url,
      "RAILS_API_URL" => ENV.fetch("RAILS_API_URL", "http://localhost:3000"),
      "RAILS_API_KEY" => Rails.application.credentials.dig(:agent, :api_key) || ENV["AGENT_API_KEY"],
      "AGENT_MODEL" => ENV.fetch("AGENT_MODEL", "claude-sonnet-4-6"),
    }.compact
  end

  def agent_database_url
    ENV["AGENT_DATABASE_URL"] || begin
      config = ActiveRecord::Base.connection_db_config.configuration_hash
      "postgresql://agent_reader:#{config[:password]}@#{config[:host] || 'localhost'}:#{config[:port] || 5432}/#{config[:database]}"
    end
  end
end
