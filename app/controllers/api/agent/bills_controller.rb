module Api
  module Agent
    class BillsController < BaseController
      def index
        parliament_number = (params[:parliament_number] || 45).to_i
        bills = Bill.where(parliament_number: parliament_number)
          .where("data->>'BillTypeEn' IN ('House Government Bill', 'Senate Government Bill')")
          .order("latest_activity_at DESC NULLS LAST")

        render json: bills.map { |b| serialize_bill_summary(b) }
      end

      def show
        bill = Bill.find(params[:id])

        linked_commitments = CommitmentMatch
          .includes(:commitment)
          .where(matchable_type: "Bill", matchable_id: bill.id)
          .order(relevance_score: :desc)
          .map do |m|
            {
              commitment_id: m.commitment_id,
              relevance_score: m.relevance_score,
              relevance_reasoning: m.relevance_reasoning,
              commitment_title: m.commitment&.title,
              commitment_status: m.commitment&.status
            }
          end

        render json: serialize_bill_summary(bill).merge(linked_commitments: linked_commitments)
      end

      private

      def serialize_bill_summary(b)
        {
          id: b.id,
          bill_id: b.bill_id,
          bill_number_formatted: b.bill_number_formatted,
          parliament_number: b.parliament_number,
          short_title: b.short_title,
          long_title: b.long_title,
          latest_activity: b.latest_activity,
          latest_activity_at: b.latest_activity_at,
          passed_house_first_reading_at: b.passed_house_first_reading_at,
          passed_house_second_reading_at: b.passed_house_second_reading_at,
          passed_house_third_reading_at: b.passed_house_third_reading_at,
          passed_senate_first_reading_at: b.passed_senate_first_reading_at,
          passed_senate_second_reading_at: b.passed_senate_second_reading_at,
          passed_senate_third_reading_at: b.passed_senate_third_reading_at,
          received_royal_assent_at: b.received_royal_assent_at
        }
      end
    end
  end
end
