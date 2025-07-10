require "csv"

class StatcanFetcher
  def self.fetch(url)
    response = HTTP
      .timeout(connect: 10, read: 60)
      .headers("User-Agent" => "BuildCanada/OutcomeTrackerAPI")
      .get(url)

    unless response.status.success?
      raise "HTTP Error: #{response.status} - #{response.status.reason}"
    end

    csv_string = response.body.to_s

    # Remove UTF-8 Byte Order Mark (BOM) if present
    csv_string = csv_string.sub(/\A\uFEFF/, "")

    CSV.parse(csv_string, headers: true, liberal_parsing: true, skip_blanks: true).map(&:to_h)
  end
end
