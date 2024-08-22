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

    # Get the recurrence option
    recurrence = params[:recurrence] || 'once'

    # Initialize array to store created availabilities
    created_availabilities = []

    # Function to create availability records for a specific start_date and end_date
    create_availabilities_for_range(start_date, end_date, start_hour, start_minute, end_hour, end_minute, created_availabilities)

    # Determine the recurrence interval
    case recurrence
    when 'weekly'
      current_date = start_date + 1.week
      while current_date <= end_date + 1.year
        create_availabilities_for_range(start_date + (current_date - start_date).to_i.days, end_date + (current_date - start_date).to_i.days, start_hour, start_minute, end_hour, end_minute, created_availabilities)
        current_date += 1.week
      end

    when 'monthly'
      current_date = start_date.next_month
      while current_date <= end_date + 1.year
        create_availabilities_for_range(start_date.next_month(current_date.month - start_date.month), end_date.next_month(current_date.month - start_date.month), start_hour, start_minute, end_hour, end_minute, created_availabilities)
        current_date = current_date.next_month
      end

    else
      # 'once' or any other value; nothing more to do here since it’s already handled
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

  def create_availabilities_for_range(start_date, end_date, start_hour, start_minute, end_hour, end_minute, created_availabilities)
    local_time_zone = Time.zone || 'UTC'  # Use Rails time zone if set, otherwise default to UTC

    (start_date..end_date).each do |date|
      # Convert to local time zone
      availability_start = Time.zone.local(date.year, date.month, date.day, start_hour, start_minute)
      availability_end = Time.zone.local(date.year, date.month, date.day, end_hour, end_minute)

      if availability_end > availability_start
        availability = Availability.new(user: current_user, start_time: availability_start, end_time: availability_end)
        authorize availability

        if availability.save
          created_availabilities << availability
        else
          flash[:alert] = "There was an issue saving one or more availabilities."
          render :new and return
        end
      end
    end
  end
end
