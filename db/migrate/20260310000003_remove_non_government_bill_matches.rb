class RemoveNonGovernmentBillMatches < ActiveRecord::Migration[8.0]
  def up
    non_gov_bill_ids = Bill.where.not("data->>'BillTypeEn' IN (?)", Bill::GOVERNMENT_BILL_TYPES).pluck(:id)
    return if non_gov_bill_ids.empty?

    CommitmentMatch.where(matchable_type: "Bill", matchable_id: non_gov_bill_ids).delete_all
  end

  def down
    # Cannot restore deleted matches
  end
end
