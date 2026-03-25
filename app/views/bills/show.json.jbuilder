json.(@bill,
  :id,
  :bill_id,
  :bill_number_formatted,
  :parliament_number,
  :short_title,
  :long_title,
  :latest_activity,
  :latest_activity_at,
  :passed_house_first_reading_at,
  :passed_house_second_reading_at,
  :passed_house_third_reading_at,
  :passed_senate_first_reading_at,
  :passed_senate_second_reading_at,
  :passed_senate_third_reading_at,
  :received_royal_assent_at,
  :data
)

json.linked_commitments @bill.commitment_matches.includes(commitment: :lead_department) do |cm|
  json.(cm, :relevance_score, :relevance_reasoning)
  json.commitment do
    json.(cm.commitment, :id, :title, :status, :commitment_type)
    json.lead_department cm.commitment.lead_department&.display_name
  end
end
