class StatcanDataset < ApplicationRecord
  has_many :commitment_matches, as: :matchable, dependent: :destroy

  validates :statcan_url, presence: true, uniqueness: true, format: { with: URI::DEFAULT_PARSER.make_regexp }
  validates :name, presence: true, uniqueness: true, format: { with: /\A[a-z0-9-]+\z/, message: "must be lowercase with hyphens only" }
  validates :sync_schedule, presence: true
  validate :valid_cron_expression

  def self.filter_stale(datasets, current_time = Time.current)
    datasets.select { |dataset| dataset.needs_sync?(current_time) }
  end

  def needs_sync?(current_time = Time.current)
    return true if last_synced_at.nil?

    cron = Fugit::Cron.parse(sync_schedule)
    last_scheduled_time = cron.previous_time(current_time)

    last_synced_at.to_i < last_scheduled_time.seconds
  end

  def sync!
    data = StatcanFetcher.fetch(statcan_url)

    raise "StatcanDataset sync failed: No data received from StatCan API" if data.blank?

    update!(current_data: data, last_synced_at: Time.current)
    filter_commitment_relevance!
  end

  def filter_commitment_relevance!(inline: false)
    unless inline
      return CommitmentRelevanceFilterJob.perform_later(self)
    end

    CommitmentRelevanceFilterJob.perform_now(self)
  end

  def format_for_llm
    <<~TEXT
    Name: #{name}
    URL: #{statcan_url}
    Data Preview: #{current_data&.first(5)&.to_json}
    TEXT
  end

  private

  def valid_cron_expression
    return unless sync_schedule.present?

    parsed_cron = Fugit::Cron.parse(sync_schedule)
    if parsed_cron.nil?
      errors.add(:sync_schedule, "must be a valid cron expression")
    end
  end
end
