class DashboardController < ApplicationController
  def day_names
    ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
  end

  def show
    @user = current_user
    authorize @user
    @date = Date.parse(params.fetch(:date, Date.today.to_s))
    @day_names = day_names
    @prev_month = @date - 1.month
    @bookings = Booking.where(user_id: @user.id, start_time: @date.all_month)
  end
end
