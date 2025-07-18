class BillsCronJob < ApplicationJob
  queue_as :default

  def perform
    Bill.sync_all
  end
end
