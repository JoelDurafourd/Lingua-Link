class AddDescriptionToBooking < ActiveRecord::Migration[7.1]
  def change
    add_column :bookings, :description, :text
  end
end
