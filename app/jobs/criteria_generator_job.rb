class CriteriaGeneratorJob < ApplicationJob
  queue_as :default

  def perform(commitment)
    commitment.generate_criteria!(inline: true)
  end
end
