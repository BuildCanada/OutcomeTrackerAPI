class Bill < ApplicationRecord
  GOVERNMENT_BILL_TYPES = [ "House Government Bill", "Senate Government Bill" ].freeze

  has_many :commitment_matches, as: :matchable, dependent: :destroy

  scope :government_bills, -> { where("data->>'BillTypeEn' IN (?)", GOVERNMENT_BILL_TYPES) }

  def government_bill?
    GOVERNMENT_BILL_TYPES.include?(data&.dig("BillTypeEn"))
  end

  STAGE_COLUMNS = %w[
    passed_house_first_reading_at passed_house_second_reading_at passed_house_third_reading_at
    passed_senate_first_reading_at passed_senate_second_reading_at passed_senate_third_reading_at
    received_royal_assent_at
  ].freeze

  def self.sync_all
    api_bills_array = BillsFetcher.fetch("https://www.parl.ca/legisinfo/en/bills/json")
    bills_attributes = api_bills_array.map { |api_data| attributes_from_api(api_data) }

    return if bills_attributes.empty?

    # Snapshot current stage dates for government bills before upsert
    existing_stages = government_bills
      .pluck(:bill_id, *STAGE_COLUMNS)
      .index_by(&:first)

    upsert_all(bills_attributes, unique_by: [ :bill_id ])

    # Detect stage changes and trigger agent evaluation for linked commitments
    detect_stage_changes(existing_stages)
  end

  def self.detect_stage_changes(existing_stages)
    government_bills.find_each do |bill|
      old = existing_stages[bill.bill_id]
      next unless old # New bill — will be caught by weekly scan

      old_stages = old[1..]
      new_stages = STAGE_COLUMNS.map { |col| bill.send(col) }

      next if old_stages == new_stages

      # Stage changed — trigger agent for all linked commitments
      bill.commitment_matches.each do |match|
        AgentEvaluateCommitmentJob.perform_later(
          match.commitment,
          trigger_type: "bill_stage_change"
        )
      end
    end
  end

  def self.attributes_from_api(api_data)
    {
      bill_id: api_data["BillId"],
      bill_number_formatted: api_data["BillNumberFormatted"],
      parliament_number: api_data["ParliamentNumber"],
      short_title: api_data["ShortTitleEn"],
      long_title: api_data["LongTitleEn"],
      latest_activity: api_data["LatestActivityEn"],
      data: api_data,
      passed_house_first_reading_at: parse_timestamp(api_data["PassedHouseFirstReadingDateTime"]),
      passed_house_second_reading_at: parse_timestamp(api_data["PassedHouseSecondReadingDateTime"]),
      passed_house_third_reading_at: parse_timestamp(api_data["PassedHouseThirdReadingDateTime"]),
      passed_senate_first_reading_at: parse_timestamp(api_data["PassedSenateFirstReadingDateTime"]),
      passed_senate_second_reading_at: parse_timestamp(api_data["PassedSenateSecondReadingDateTime"]),
      passed_senate_third_reading_at: parse_timestamp(api_data["PassedSenateThirdReadingDateTime"]),
      received_royal_assent_at: parse_timestamp(api_data["ReceivedRoyalAssentDateTime"]),
      latest_activity_at: parse_timestamp(api_data["LatestActivityDateTime"]),
      updated_at: Time.current
    }
  end

  def filter_commitment_relevance!(inline: false)
    unless inline
      return CommitmentRelevanceFilterJob.perform_later(self)
    end

    CommitmentRelevanceFilterJob.perform_now(self)
  end

  def format_for_llm
    <<~TEXT
    Bill Number: #{bill_number_formatted}
    Short Title: #{short_title}
    Long Title: #{long_title}
    Latest Activity: #{latest_activity}
    TEXT
  end

  private_class_method def self.parse_timestamp(timestamp_string)
    return nil if timestamp_string.blank?
    Time.parse(timestamp_string)
  end
end
