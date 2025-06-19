class Promise < ApplicationRecord
  has_many :evidences, dependent: :destroy
  def format_for_llm
    {
      promise_id: promise_id,
      title: concise_title,
      description: description
    }
  end
end
