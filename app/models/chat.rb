class Chat < ApplicationRecord
  acts_as_chat

  belongs_to :record, polymorphic: true, optional: true

  class << self
    # Rows from retired pipelines (CriterionAssessor, CommitmentStatusDeriver) remain as an
    # audit log after their classes were removed. Load them as plain Chats instead of raising.
    def find_sti_class(type_name)
      super
    rescue ActiveRecord::SubclassNotFound
      self
    end
  end

  def system_prompt
  end

  def extract!(prompt)
    raise unless self.class.respond_to?(:json_schema)

    chat = self.with_schema(self.class.json_schema)

    if self.system_prompt.present?
      chat = chat.with_instructions(self.system_prompt)
    end

    message = chat.ask(prompt)

    attributes = JSON.parse(message.content)

    if attributes.nil?
      raise "Nil response from LLM, message: #{message.inspect}"
    end

    self.update(attributes)
  end
end
