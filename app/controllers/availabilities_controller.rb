class AvailabilitiesController < ApplicationController
  def index
    # Fetch the current date or use the provided start_date parameter
    start_date = params.fetch(:start_date, Date.today).to_date

    # Query availabilitys for the current month, adjusting the range to cover the entire month
    @availabilities = Availability.where(start_time: start_date.beginning_of_month..start_date.end_of_month)
  end

  def show
    # this shows a singular avialability, usually the avialability attached to the page or whatever link you're clicking on.
    @availability = Availability.find(params[:id])
  end

  def new
    # creates a new availability
    @availability = Availability.new(user: current_user)
    @user = current_user
    authorize @availability
  end

  def create
    # Parse dates and times from parameters
    start_date = Date.parse(params[:start_time])
    end_date = Date.parse(params[:end_time])

    # Extract hour and minute values and create Time objects
    start_hour = params[:start_time_hour].to_i
    start_minute = params[:start_time_minute].to_i
    end_hour = params[:end_time_hour].to_i
    end_minute = params[:end_time_minute].to_i

    # Initialize start_time and end_time with the start_date's year, month, and day
    start_time = Time.new(start_date.year, start_date.month, start_date.day, start_hour, start_minute)
    end_time = Time.new(start_date.year, start_date.month, start_date.day, end_hour, end_minute)

    # Initialize current_date and array to store created availabilities
    current_date = start_date
    created_availabilities = []

    while current_date <= end_date
      # Combine current_date with start_time and end_time
      availability_start = current_date.to_datetime.change(hour: start_time.hour, min: start_time.min)
      availability_end = current_date.to_datetime.change(hour: end_time.hour, min: end_time.min)

      # Ensure availability_end is after availability_start
      if availability_end > availability_start
        availability = Availability.new(user: current_user, start_time: availability_start, end_time: availability_end)

        # Authorize the availability record
        authorize availability

        if availability.save
          created_availabilities << availability
        else
          flash[:alert] = "There was an issue saving one or more availabilities."
          render :new and return
        end
      end

      # Move to the next day
      current_date += 1.day
    end

    # Redirect to the dashboard with a success notice
    redirect_to dashboard_path(current_user), notice: "#{created_availabilities.count} availability(s) successfully created!"
  end

  def edit
    # find the availability to edit
    @availability = Availability.find(params[:id])
  end

  def update
    # update using security params below
    @availability = Availability.find(params[:id])
    if @availability.update(availability_params)
      # if the current availability is saved succesfully, redirect to the availability page
      redirect_to dashboard_path(@user)
    else
      # else display an error message
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    # find availability, delete it, then redired to its original lesson it came from.
    @availability = Availability.find(params[:id])
    @availability.destroy
    redirect_to dashboard_path(@availability.user), status: :see_other
  end

  def set_user
    @user = User.find(params[:user_id])
  end

  def set_availability
    @availability = Availability.find(params[:id])
  end

  private

  def availability_params
    # these are strong params or security params, it makes sure only these attributes are changed. Any edits to a model has to be modified here also.
    params.require(:availability).permit(:start_time, :end_time, :client_id)
  end
end
