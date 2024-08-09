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
    @prev_week = @date - 1.week
    @bookings = Booking.where(user_id: @user.id, start_time: @date.all_month)
  end

  def week
    @user = User.find(params[:user_id])
    authorize @user
    @day_names = day_names
    @date = Date.parse(params.fetch(:date, Date.today.to_s))
    @prev_week = @date - 1.week
    @bookings = Booking.where(user_id: @user.id, start_time: @date.all_week)
  end
end
