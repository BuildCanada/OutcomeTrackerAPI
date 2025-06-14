require "ruby_llm"
require "env_or_credentials"

RubyLLM.configure do |config|
    config.gemini_api_key = EnvOrCredentials.fetch("GEMINI_API_KEY", :gemini_api_key)

    config.default_model = "gemini-2.0-flash-lite"               # Default: 'gpt-4.1-nano'
    config.default_embedding_model = "text-embedding-004"  # Default: 'text-embedding-3-small'
    config.default_image_model = "dall-e-3"            # Default: 'dall-e-3'

  # Add other keys like config.anthropic_api_key if needed
end
