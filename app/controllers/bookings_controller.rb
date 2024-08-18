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
    @booking = Booking.new(booking_params.merge(user: current_user))
    @user = current_user

    authorize @booking

    if available_for_booking?(@booking)
      if @booking.save
        redirect_to dashboard_path(@user), notice: 'Booking successfully created!'
      else
        render :new, status: :unprocessable_entity
      end
    else
      flash[:alert] =
        'The selected time slot is either unavailable or overlaps with an existing booking. Please choose a different time.'
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
    authorize @booking
    return unless @booking.update(status: :accepted)

    line_service = LineService.new
    teacher = User.find_by(id: @booking.user_id)
    student = @booking.client

    line_service.push_message(
      student.lineid,
      {
        type: "text",
        text: "Your booked a lesson on #{@booking.start_time.strftime('%A, %B %d, %Y')} at #{@booking.start_time.strftime('%I:%M %p')} has been Accepted by #{teacher.first_name}."
      }
    )
    redirect_to user_path(@booking.user)
  end

  def decline
    # change the bookings status to declined, redirect to the booking path
    @booking = Booking.find(params[:id])
    return unless @booking.update(status: :declined)

    redirect_to user_path(@booking.user)
  end

  def set_user
    @user = User.find(params[:user_id])
  end

  def set_booking
    @booking = Booking.find(params[:id])
  end

  private

  private

  def available_for_booking?(booking)
    # Fetch availability for the current user
    availabilities = Availability.where(user: booking.user)

    # Fetch existing bookings for the current user
    existing_bookings = Booking.where(user: booking.user)
    # Check if the booking time falls within any available slot
    is_available = availabilities.any? do |availability|
      booking.start_time < availability.end_time && booking.end_time > availability.start_time
    end

    # Check if the booking time overlaps with any existing bookings
    is_not_double_booked = existing_bookings.none? do |existing_booking|
      booking.start_time < existing_booking.end_time && booking.end_time > existing_booking.start_time
    end

    # Both conditions must be met
    is_available && is_not_double_booked
  end

  def booking_params
    # these are strong params or security params, it makes sure only these attributes are changed. Any edits to a model has to be modified here also.
    params.require(:booking).permit(:start_time, :end_time, :client_id, :status, :title, :description)
  end
end
# t.datetime "start_time"
# t.datetime "end_time"
# t.bigint "user_id", null: false
# t.bigint "client_id", null: false
