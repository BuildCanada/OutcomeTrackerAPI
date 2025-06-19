class Chat < ApplicationRecord
  acts_as_chat

  belongs_to :record, polymorphic: true, optional: true

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

    self.update(attributes)
  end
end
