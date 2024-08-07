class CalendarsController < ApplicationController
  def day_names
    ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
  end

  def month
    @user = User.find(params[:user_id])
    authorize @user
    @day_names = day_names
  end
end
