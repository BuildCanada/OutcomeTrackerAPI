# Fetches external pages with a consistent crawler identity.
#
# canada.ca's edge rejects bare bot-style and spoofed-browser User-Agents (connection reset
# or indefinite hang) but accepts an honest "compatible" crawler string with a contact URL.
module PageFetcher
  USER_AGENT = "Mozilla/5.0 (compatible; BuildCanadaTracker/1.0; +https://buildcanada.com)".freeze

  class << self
    def get(url, connect: 5, read: 20, max_hops: 3)
      HTTP.timeout(connect: connect, read: read)
        .headers("User-Agent" => USER_AGENT)
        .follow(max_hops: max_hops)
        .get(url)
    end
  end
end
