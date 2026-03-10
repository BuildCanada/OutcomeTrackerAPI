class Entry < ApplicationRecord
  include Structify::Model

  belongs_to :feed
  belongs_to :government
  belongs_to :parent, class_name: "Entry", inverse_of: :children, optional: true
  has_many :activity_extractors, as: :record
  has_many :activities
  has_many :evidences, through: :activities
  has_many :promises, through: :evidences

  has_many :children, class_name: "Entry", foreign_key: "parent_id"
  has_many :commitment_matches, as: :matchable, dependent: :destroy


  after_commit :fetch_data!, on: [ :create ]

  validates :url, presence: true, uniqueness: true

  def self.ransackable_attributes(auth_object = nil)
    [ "title", "summary", "url" ]
  end


  def fetch_data!(inline: false)
    # TODO: make this more robust, this should not be configured globally.
    # Track parliament session dates for matching?
    if self.url.start_with?("mailto:")
      self.skipped_at = Time.now
      self.skip_reason = "Mailto url not a proper entry"
      self.save!
      return
    elsif self.published_at.present? && self.published_at < Time.parse("2025-04-28")
      self.skipped_at = Time.now
      self.skip_reason = "Too old, published before 2025-04-28 (Carney's election)"
      self.save!
      return
    else
      self.skipped_at = nil
      self.skip_reason = nil
    end

    unless inline
      return EntryDataFetcherJob.perform_later(self)
    end
    # Fetch data from external source

    r = HTTP.timeout(connect: 10, read: 30).get(url)

    if r.status >= 300 or r.status < 200
      Rails.logger.error("Error fetching data for entry #{id}: #{r.status}")
      raise HTTP::Error.new("Failed to fetch #{url} Status code #{r.status}")
    end
    self.raw_html = Defuddle.prepare_html(r.body.to_s)

    self.parsed_markdown, self.parsed_html = Defuddle.defuddle(raw_html)
    self.scraped_at = Time.now

    self.is_index = document_relative_links.any?
    self.save!

    if is_index
      create_subentries! if parent.nil? # only create subentries if this is the top-level entry
    else
      extract_activities!
      filter_commitment_relevance!
    end
  rescue => e
    Rails.logger.error("Error fetching data for entry #{id}: #{e.message}")
    raise e
  end

  def create_subentries!
    # get any document relative links from the html, this is somewhat specific to Canada Gazette, but we'll handle
    # other edge cases when they come up.
    document_relative_links.each do |relative_link, link, text|
      Entry.find_or_create_by!(government: government, feed: feed, url: link) do |rec|
        rec.title = text.gsub(/\s+/, " ").strip # remove any extra whitespace and trim
        rec.published_at = published_at
        rec.parent = self
      end
    end
  end

  def document_relative_links
    HtmlExtractor.extract_links_with_text(raw_html, url, include: [ :document_relative ])
  end

  def extract_activities!(inline: false)
    unless inline
      return EntryActivityExtractorJob.perform_later(self)
    end
    extractor = ActivityExtractor.create!(record: self)
    extractor.extract_activities!
    self.activities_extracted_at = Time.now
    self.save!
  end

  def filter_commitment_relevance!(inline: false)
    unless inline
      return CommitmentRelevanceFilterJob.perform_later(self)
    end

    CommitmentRelevanceFilterJob.perform_now(self)
  end

  def format_for_llm
    <<~XML
    <political_artifact>
      <source>#{feed.title}</source>
      <published_at>#{published_at}</published_at>
      <title>#{title}</title>
      <summary>#{summary}</summary>
      <content>#{parsed_markdown}</content>
    </political_artifact>
    XML
  end
end
