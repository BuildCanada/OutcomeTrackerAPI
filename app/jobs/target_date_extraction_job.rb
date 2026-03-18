class TargetDateExtractionJob < ApplicationJob
  queue_as :default

  def perform(commitment)
    return if commitment.target_date.present?

    extractor = TargetDateExtractor.create!(record: commitment)
    extractor.extract!(extractor.prompt(commitment))

    target_date_str = extractor.extraction&.dig("target_date")
    return if target_date_str.blank?

    parsed_date = Date.parse(target_date_str)
    commitment.update!(target_date: parsed_date)

    Rails.logger.info("TargetDateExtractionJob: Set target_date=#{parsed_date} for commitment ##{commitment.id}: #{extractor.extraction['reasoning']}")
  rescue Date::Error => e
    Rails.logger.warn("TargetDateExtractionJob: Failed to parse date '#{target_date_str}' for commitment ##{commitment.id}: #{e.message}")
  end
end
