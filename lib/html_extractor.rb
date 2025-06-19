require "nokogiri"
require "uri"


module HtmlExtractor
  def self.extract_links_with_text(html, source_url, include: [ :hashes, :absolute, :document_relative, :root_relative ])
    include_set = include.to_set

    doc = Nokogiri::HTML(html)
    base_uri = URI.parse(source_url)
    base_dir = base_uri.path.end_with?("/") ? base_uri : base_uri.dup.tap { |u| u.path = File.dirname(base_uri.path) + "/" }

    doc.css("a[href]").map do |a_tag|
      href = a_tag["href"]
      next if href.nil? || href.empty?

      type =
        case href
        when /\Ahttps?:\/\//
          :absolute
        when /\A\/(?!\/)/
          :root_relative
        when /\A#/
          :hashes
        else
          :document_relative
        end

      next unless include_set.include?(type)

      begin
        absolute_url = URI.join(base_dir.to_s, href).to_s
        [ href, absolute_url, a_tag.text.strip ]
      rescue URI::InvalidURIError
        nil
      end
    end.compact
  end
end
