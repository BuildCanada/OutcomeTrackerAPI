module Api
  module Agent
    class PagesController < BaseController
      ALLOWED_SUFFIXES = %w[.canada.ca .gc.ca].freeze

      def fetch
        url = params.require(:url)
        government_id = params.require(:government_id)

        unless government_url?(url)
          render json: { error: "URL must be on a *.canada.ca or *.gc.ca domain" }, status: :unprocessable_entity
          return
        end

        # Fetch and parse the page
        response = HTTP.timeout(connect: 5, read: 20)
          .headers("User-Agent" => "BuildCanada-Tracker/1.0")
          .follow(max_hops: 3)
          .get(url)

        unless response.status.success?
          render json: { error: "Failed to fetch: HTTP #{response.status}" }, status: :bad_gateway
          return
        end

        final_url = response.uri.to_s

        unless government_url?(final_url)
          render json: { error: "Redirect led to non-government domain: #{final_url}" }, status: :unprocessable_entity
          return
        end

        # Parse HTML to markdown
        prepared_html = Defuddle.prepare_html(response.body.to_s)
        parsed_markdown, _parsed_html = Defuddle.defuddle(prepared_html)

        # Extract title and date from meta tags
        doc = Nokogiri::HTML(response.body.to_s)
        title = doc.at_css("title")&.text&.strip || ""
        published_date = doc.at_css('meta[name="dcterms.modified"]')&.[]("content") ||
                         doc.at_css('meta[name="dcterms.issued"]')&.[]("content")

        # Truncate very long pages
        if parsed_markdown && parsed_markdown.length > 15_000
          parsed_markdown = parsed_markdown[0, 15_000] + "\n\n[Content truncated at 15,000 characters]"
        end

        # Auto-create source record
        source = Source.find_or_create_by!(url: final_url) do |s|
          s.government_id = government_id
          s.title = title.presence || "Government page: #{final_url}"
          s.source_type = infer_source_type(final_url)
          s.source_type_other = "government_webpage" if s.source_type == "other"
          s.date = published_date
        end

        render json: {
          url: final_url,
          title: title,
          content_markdown: parsed_markdown,
          published_date: published_date,
          source_id: source.id,
          source_existed: !source.previously_new_record?
        }
      end

      private

      def government_url?(url)
        host = URI.parse(url).host
        return false unless host
        ALLOWED_SUFFIXES.any? { |suffix| host == suffix.delete_prefix(".") || host.end_with?(suffix) }
      rescue URI::InvalidURIError
        false
      end

      def infer_source_type(url)
        case url
        when /gazette\.gc\.ca/ then "gazette_notice"
        when /budget|finance/ then "budget"
        when /parl\.ca|legisinfo/ then "other"
        when /orders?-in-council|oic|privy/ then "order_in_council"
        else "other"
        end
      end
    end
  end
end
