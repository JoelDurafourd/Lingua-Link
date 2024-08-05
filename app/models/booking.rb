class Booking < ApplicationRecord
  belongs_to :user
  belongs_to :client
  validates :start_time, presence: true
  validates :end_time, presence: true, comparison: { greater_than: :start_time }
end
