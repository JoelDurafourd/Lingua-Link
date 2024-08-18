class AddTitleToBooking < ActiveRecord::Migration[7.1]
  def change
    add_column :bookings, :title, :string
  end
end
