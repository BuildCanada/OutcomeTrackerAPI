require "http"
require "json"

# Client for the hosted BuildCanada defuddle worker, which extracts the main content of a
# web page and returns it as markdown plus a cleaned HTML fragment.
#
# Configure with DEFUDDLE_API_KEY (required) and DEFUDDLE_API_URL (optional).
module Defuddle
  class ParseError < StandardError; end

  DEFAULT_API_URL = "https://deffudler.svc.canadasbuilding.com".freeze

  class << self
    # Sends already-fetched HTML to the worker and returns [markdown_content, html_content].
    # The page URL is passed along so relative links and site-specific rules resolve correctly.
    def defuddle(html, url:)
      response = HTTP.timeout(connect: 5, read: 60)
        .headers("X-API-Key" => api_key, "Content-Type" => "application/json")
        .post("#{api_url}/api/convert", json: { url: url, html: html })

      body = JSON.parse(response.body.to_s)
      raise ParseError, "defuddle service returned HTTP #{response.status}: #{body["error"]}" unless response.status.success?

      [ body["content"], body["html"] ]
    rescue HTTP::Error, JSON::ParserError => e
      raise ParseError, "defuddle service request failed: #{e.message}"
    end

    def prepare_html(html)
      ic = Iconv.new("UTF-8//IGNORE", "UTF-8")

      ic.iconv(html + " ")[0..-2]
    end

    private

    def api_url
      ENV.fetch("DEFUDDLE_API_URL", DEFAULT_API_URL).chomp("/")
    end

    def api_key
      ENV["DEFUDDLE_API_KEY"].presence || raise(ParseError, "DEFUDDLE_API_KEY is not set")
    end
  end
end
