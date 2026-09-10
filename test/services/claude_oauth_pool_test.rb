require "test_helper"

class ClaudeOauthPoolTest < ActiveSupport::TestCase
  setup do
    @original = ENV.to_h.slice("CLAUDE_CODE_OAUTH_TOKENS", "CLAUDE_CODE_OAUTH_TOKEN")
    ENV.delete("CLAUDE_CODE_OAUTH_TOKENS")
    ENV.delete("CLAUDE_CODE_OAUTH_TOKEN")
  end

  teardown do
    ENV.delete("CLAUDE_CODE_OAUTH_TOKENS")
    ENV.delete("CLAUDE_CODE_OAUTH_TOKEN")
    @original.each { |key, value| ENV[key] = value }
  end

  test "no credentials preserves CLI authentication" do
    assert_nil ClaudeOauthPool.pick
    assert_empty ClaudeOauthPool.secrets
  end

  test "singular fallback is used for empty pool" do
    ENV["CLAUDE_CODE_OAUTH_TOKENS"] = "{}"
    ENV["CLAUDE_CODE_OAUTH_TOKEN"] = "fallback-secret"
    credential = ClaudeOauthPool.pick
    assert_equal "fallback-secret", credential.token
    assert_equal "default", credential.label
    assert_equal Digest::SHA256.hexdigest("fallback-secret"), credential.fingerprint
    refute_includes credential.inspect, "fallback-secret"
  end

  test "pool overrides fallback but redacts all configured secrets and deduplicates" do
    ENV["CLAUDE_CODE_OAUTH_TOKENS"] = { "one" => "first-secret", "duplicate" => "first-secret", "two" => "second-secret" }.to_json
    ENV["CLAUDE_CODE_OAUTH_TOKEN"] = "fallback-secret"
    assert_equal 2, ClaudeOauthPool.credentials.size
    assert_equal %w[first-secret second-secret fallback-secret], ClaudeOauthPool.secrets
    10.times do
      assert_includes %w[first-secret second-secret], ClaudeOauthPool.pick.token
    end
  end

  test "pick delegates to random sample each time" do
    first = ClaudeOauthPool::Credential.new(label: "one", token: "first")
    second = ClaudeOauthPool::Credential.new(label: "two", token: "second")
    choices = [ first, second ]
    ClaudeOauthPool.stub(:credentials, choices) do
      choices.stub(:sample, second) { assert_same second, ClaudeOauthPool.pick }
      choices.stub(:sample, first) { assert_same first, ClaudeOauthPool.pick }
    end
  end

  test "invalid configuration errors never echo tokens" do
    [ "{private-token", '["private-token"]', '{"one":42}', '{"one":""}' ].each do |value|
      ENV["CLAUDE_CODE_OAUTH_TOKENS"] = value
      error = assert_raises(ClaudeOauthPool::ConfigurationError) { ClaudeOauthPool.pick }
      refute_includes error.message, "private-token"
    end
  end
end
