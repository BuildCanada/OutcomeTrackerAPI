require "open3"

class AgentProcessEntryJob < ApplicationJob
  queue_as :default

  def perform(entry)
    agent_dir = Rails.root.join("agent")

    args = [
      "python", "-m", "agent.main", "process-entry",
      "--entry-id", entry.id.to_s
    ]

    env = agent_env

    Rails.logger.info("AgentProcessEntryJob: Processing entry #{entry.id} (#{entry.title})")

    stdout, stderr, status = Open3.capture3(env, *args, chdir: agent_dir.to_s)

    if status.success?
      Rails.logger.info("AgentProcessEntryJob: Success for entry #{entry.id}")
      Rails.logger.debug(stdout) if stdout.present?
    else
      Rails.logger.error("AgentProcessEntryJob: Failed for entry #{entry.id}")
      Rails.logger.error(stderr) if stderr.present?
      raise "Agent processing failed for entry #{entry.id}: #{stderr.first(500)}"
    end
  end

  private

  def agent_env
    {
      "ANTHROPIC_API_KEY" => Rails.application.credentials.dig(:anthropic, :api_key) || ENV["ANTHROPIC_API_KEY"],
      "AGENT_DATABASE_URL" => agent_database_url,
      "RAILS_API_URL" => ENV.fetch("RAILS_API_URL", "http://localhost:3000"),
      "RAILS_API_KEY" => Rails.application.credentials.dig(:agent, :api_key) || ENV["AGENT_API_KEY"],
      "AGENT_MODEL" => ENV.fetch("AGENT_MODEL", "claude-opus-4-6"),
    }.compact
  end

  def agent_database_url
    ENV["AGENT_DATABASE_URL"] || begin
      config = ActiveRecord::Base.connection_db_config.configuration_hash
      "postgresql://agent_reader:#{config[:password]}@#{config[:host] || 'localhost'}:#{config[:port] || 5432}/#{config[:database]}"
    end
  end
end
