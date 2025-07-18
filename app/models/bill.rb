class Bill < ApplicationRecord
  def self.sync_all
    api_bills_array = BillsFetcher.fetch("https://www.parl.ca/legisinfo/en/bills/json")
    bills_attributes = api_bills_array.map { |api_data| attributes_from_api(api_data) }

    return if bills_attributes.empty?

    upsert_all(bills_attributes, unique_by: [ :bill_id ])
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

  private_class_method def self.parse_timestamp(timestamp_string)
    return nil if timestamp_string.blank?
    Time.parse(timestamp_string)
  end
end
