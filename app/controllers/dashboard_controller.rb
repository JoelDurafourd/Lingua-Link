class DashboardController < ApplicationController
  before_action :show_welcome_message, only: %i[show week]
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
    @booking = Booking.new
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

  def show_welcome_message
    @show_welcome_message = !session[:welcome_message_shown]
    session[:welcome_message_shown] = true if @show_welcome_message
  end
end
