class Promise < ApplicationRecord
  has_many :evidences, dependent: :destroy
  has_many :activities, through: :evidences
  has_many :entries, through: :activities

  def format_for_llm
    {
      promise_id: promise_id,
      title: concise_title,
      description: description
    }
  end
end
