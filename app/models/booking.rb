class Booking < ApplicationRecord
  belongs_to :user
  belongs_to :client

  enum status: { pending: 0, accepted: 1, declined: 2, canceled: 3 }
  validates :start_time, presence: true
  validates :end_time, presence: true, comparison: { greater_than: :start_time }
end
# t.datetime "start_time"
# t.datetime "end_time"
# t.bigint "user_id", null: false
# t.bigint "client_id", null: false
