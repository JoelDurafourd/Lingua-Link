class Client < ApplicationRecord
  # t.string "lineid"
  # t.string "phone_number"
  # t.string "name"

  has_many :bookings, dependent: :destroy
end
