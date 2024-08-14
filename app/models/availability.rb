class Availability < ApplicationRecord
  belongs_to :user

  validates :start_time, :end_time, presence: true
end
