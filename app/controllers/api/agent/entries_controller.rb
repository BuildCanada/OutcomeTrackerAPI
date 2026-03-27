module Api
  module Agent
    class EntriesController < BaseController
      def index
        scope = Entry.includes(:feed).where.not(scraped_at: nil).where(skipped_at: nil, is_index: [ false, nil ])

        if params[:unprocessed] == "true"
          scope = scope.where(agent_processed_at: nil)
        end

        if params[:government_id].present?
          scope = scope.where(government_id: params[:government_id])
        end

        limit = (params[:limit] || 50).to_i
        entries = scope.order(published_at: :desc).limit(limit)

        render json: entries.map { |e|
          {
            id: e.id, title: e.title, url: e.url,
            published_at: e.published_at, scraped_at: e.scraped_at,
            activities_extracted_at: e.activities_extracted_at,
            feed_title: e.feed&.title,
          }
        }
      end

      def show
        entry = Entry.includes(:feed).find(params[:id])
        render json: {
          id: entry.id,
          title: entry.title,
          url: entry.url,
          published_at: entry.published_at,
          scraped_at: entry.scraped_at,
          summary: entry.summary,
          parsed_markdown: entry.parsed_markdown,
          activities_extracted_at: entry.activities_extracted_at,
          feed_title: entry.feed&.title,
          feed_source_url: entry.feed&.source_url,
        }
      end

      def mark_processed
        entry = Entry.find(params[:id])

        if entry.agent_processed_at.present?
          render json: { id: entry.id, agent_processed_at: entry.agent_processed_at, skipped: true }
          return
        end

        entry.update!(agent_processed_at: Time.current)
        render json: { id: entry.id, agent_processed_at: entry.agent_processed_at, skipped: false }
      end
    end
  end
end
