class BookingsController < ApplicationController
  def index
    # Fetch the current date or use the provided start_date parameter
    start_date = params.fetch(:start_date, Date.today).to_date

    # Query bookings for the current month, adjusting the range to cover the entire month
    @bookings = Booking.where(start_time: start_date.beginning_of_month..start_date.end_of_month)
  end

  def show
    # this shows a singular lesson, usually the lesson attached to the page or whatever link you're clicking on.
    @booking = Booking.find(params[:id])
    authorize @booking
  end

  def new
    # creates a new booking
    @booking = Booking.new(user: current_user)
    @user = current_user
    authorize @booking
  end

  def create
    # creates a new booking based on provided inputs, it uses private security params below.
    @booking = Booking.new(booking_params.merge(user: current_user))
    @user = current_user
    authorize @booking
    # assigns current user to the booking
    if @booking.save
      # if the current booking is created succesfully, redirect to the lesson it was booked from
      redirect_to dashboard_path(current_user), notice: 'Booking successfully created!'
    else
      # else display an error message
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    # find the booking to edit
    @booking = Booking.find(params[:id])
    @user = User.find(params[:user_id])
    authorize @booking
  end

  def update
    # update using security params below
    @booking = Booking.find(params[:id])
    if @booking.update(booking_params)
      # if the current booking is saved succesfully, redirect to the booking page
      redirect_to dashboard_path(@user)
    else
      # else display an error message
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    # find booking, delete it, then redired to its original lesson it came from.
    @booking = Booking.find(params[:id])
    @booking.destroy
    redirect_to dashboard_path(@booking.user), status: :see_other
  end

  def accept
    # change the bookings status to accepted, redirect to the booking path
    @booking = Booking.find(params[:id])
    if @booking.update(status: :accepted)
      redirect_to user_path(@booking.user)
    end
  end

  def decline
    # change the bookings status to declined, redirect to the booking path
    @booking = Booking.find(params[:id])
    if @booking.update(status: :declined)
      redirect_to user_path(@booking.user)
    end
  end

  def set_user
    @user = User.find(params[:user_id])
  end

  def set_booking
    @booking = Booking.find(params[:id])
  end

  private

  def booking_params
    # these are strong params or security params, it makes sure only these attributes are changed. Any edits to a model has to be modified here also.
    params.require(:booking).permit(:start_time, :end_time, :client_id, :status)
  end
end
# t.datetime "start_time"
# t.datetime "end_time"
# t.bigint "user_id", null: false
# t.bigint "client_id", null: false
