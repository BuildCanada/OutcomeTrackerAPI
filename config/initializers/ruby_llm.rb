require "ruby_llm"
require "env_or_credentials"

RubyLLM.configure do |config|
    config.gemini_api_key = EnvOrCredentials.fetch("GEMINI_API_KEY", :gemini_api_key)

    config.default_model = "gemini-3.1-flash-lite-preview"        # Default: 'gpt-4.1-nano'
    config.default_embedding_model = "text-embedding-004"  # Default: 'text-embedding-3-small'
    config.default_image_model = "dall-e-3"            # Default: 'dall-e-3'

  config.request_timeout = 300

  # Add other keys like config.anthropic_api_key if needed
end

# Refresh model registry so latest Gemini models are available
Rails.application.config.after_initialize do
  RubyLLM.models.refresh!
rescue => e
  Rails.logger.warn("Failed to refresh RubyLLM model registry: #{e.message}")
end
