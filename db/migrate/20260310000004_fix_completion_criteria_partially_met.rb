class FixCompletionCriteriaPartiallyMet < ActiveRecord::Migration[8.0]
  def up
    Criterion.where(category: :completion, status: :partially_met).find_each do |criterion|
      criterion.update!(status: :not_met)
    end
  end

  def down
    # Cannot determine which were originally partially_met
  end
end
