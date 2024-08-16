class Message < ApplicationRecord
  belongs_to :user
  belongs_to :client

  # after_create :translate_message

  # def translate_message
  #   TranslateMessageJob.perform_later(id)
  # end
end
