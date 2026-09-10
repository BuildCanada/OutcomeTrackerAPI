require "digest"

# Tokens remain in process memory; only labels and fingerprints identify selections.
class ClaudeOauthPool
  class ConfigurationError < StandardError; end

  class Credential
    attr_reader :token, :label, :fingerprint

    def initialize(label:, token:)
      @label, @token = label, token
      @fingerprint = Digest::SHA256.hexdigest(token)
    end

    def inspect
      "#<ClaudeOauthPool::Credential fingerprint=#{fingerprint}>"
    end
  end

  def self.configured_pool
    raw = ENV["CLAUDE_CODE_OAUTH_TOKENS"].presence
    values = raw ? JSON.parse(raw) : {}
    unless values.is_a?(Hash) && values.all? { |label, token| label.is_a?(String) && token.is_a?(String) && token.present? }
      raise ConfigurationError, "CLAUDE_CODE_OAUTH_TOKENS must be a JSON object of labels to nonempty tokens"
    end
    values
  rescue JSON::ParserError
    raise ConfigurationError, "CLAUDE_CODE_OAUTH_TOKENS must be valid JSON", cause: nil
  end

  def self.credentials
    values = configured_pool
    values["default"] = ENV["CLAUDE_CODE_OAUTH_TOKEN"] if values.empty? && ENV["CLAUDE_CODE_OAUTH_TOKEN"].present?
    values.map { |label, token| Credential.new(label: label, token: token) }.uniq(&:fingerprint)
  end

  def self.pick
    credentials.sample
  end

  def self.secrets
    (configured_pool.values + [ ENV["CLAUDE_CODE_OAUTH_TOKEN"] ]).compact.reject(&:blank?).uniq
  end
end
