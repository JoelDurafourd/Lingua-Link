class Client < ApplicationRecord
  # t.string "lineid"
  # t.string "phone_number"
  # t.string "name"
  has_and_belongs_to_many :users

  has_many :bookings, dependent: :destroy
  has_many :notes, dependent: :destroy
  has_many :messages, dependent: :destroy

  has_one_attached :photo

  scope :with_translations_enabled, -> { where(enable_translations: true) }

  # Method to toggle translations
  def toggle_translations!
    update(enable_translations: !enable_translations)
  end

  # Check if the client is chatting with any teacher
  def chatting?
    user_chat_id.present?
  end

  # Check if the client is chatting with a specific teacher
  def chatting_with_teacher?(teacher_id)
    user_chat_id == teacher_id
  end

  # Check if the client is chatting with a different teacher
  def chatting_with_another_teacher?(teacher_id)
    chatting? && user_chat_id != teacher_id
  end
end
