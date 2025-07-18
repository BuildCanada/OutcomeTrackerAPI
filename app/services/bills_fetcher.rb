require "json"

class BillsFetcher
  def self.fetch(url)
    response = HTTP
      .timeout(connect: 10, read: 60)
      .headers("User-Agent" => "BuildCanada/OutcomeTrackerAPI")
      .get(url)

    unless response.status.success?
      raise "HTTP Error: #{response.status} - #{response.status.reason}"
    end

    JSON.parse(response.body)
  end
end
