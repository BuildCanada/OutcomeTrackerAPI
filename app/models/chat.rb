class Chat < ApplicationRecord
  acts_as_chat

  belongs_to :record, polymorphic: true
end
