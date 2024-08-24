class Client < ApplicationRecord
  # t.string "lineid"
  # t.string "phone_number"
  # t.string "name"
  has_and_belongs_to_many :users

  has_many :bookings, dependent: :destroy
  has_many :notes, dependent: :destroy
  
  has_one_attached :photo

  scope :with_translations_enabled, -> { where(enable_translations: true) }

  # Method to toggle translations
  def toggle_translations!
    update(enable_translations: !enable_translations)
  end
end
