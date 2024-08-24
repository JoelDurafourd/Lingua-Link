class AvailabilitiesController < ApplicationController
  before_action :set_availability, only: %i[show edit update destroy]
  before_action :set_user, only: %i[new create]

  def index
    start_date = params.fetch(:start_date, Date.today).to_date
    @availabilities = Availability.where(start_time: start_date.beginning_of_month..start_date.end_of_month)
  end

  def show
    authorize @availability
  end

  def new
    @availability = Availability.new(user: current_user)
    authorize @availability
  end

  def create
    start_date = Date.parse(params[:start_time])
    end_date = Date.parse(params[:end_time])
    start_hour = params[:start_time_hour].to_i
    start_minute = params[:start_time_minute].to_i
    end_hour = params[:end_time_hour].to_i
    end_minute = params[:end_time_minute].to_i
    recurrence = params[:recurrence] || 'once'
    created_availabilities = []

    create_availabilities_for_range(start_date, end_date, start_hour, start_minute, end_hour, end_minute,
                                    created_availabilities)

    case recurrence
    when 'weekly'
      current_date = start_date + 1.week
      while current_date <= end_date + 1.year
        create_availabilities_for_range(start_date + (current_date - start_date).to_i.days,
                                        end_date + (current_date - start_date).to_i.days, start_hour, start_minute, end_hour, end_minute, created_availabilities)
        current_date += 1.week
      end

    when 'monthly'
      current_date = start_date.next_month
      while current_date <= end_date + 1.year
        create_availabilities_for_range(start_date.next_month(current_date.month - start_date.month),
                                        end_date.next_month(current_date.month - start_date.month), start_hour, start_minute, end_hour, end_minute, created_availabilities)
        current_date = current_date.next_month
      end

    end

    redirect_to dashboard_path(current_user),
                notice: "#{created_availabilities.count} availability(s) successfully created!"
  end

  def edit
    authorize @availability
  end

  def update
    authorize @availability
    if @availability.update(availability_params)
      redirect_to dashboard_path(@user)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @availability
    @availability.destroy
    redirect_to dashboard_path(@availability.user), status: :see_other
  end

  private

  def set_availability
    @availability = Availability.find(params[:id])
  end

  def set_user
    @user = User.find(params[:user_id])
  end

  def availability_params
    params.require(:availability).permit(:start_time, :end_time, :client_id)
  end

  def create_availabilities_for_range(start_date, end_date, start_hour, start_minute, end_hour, end_minute,
                                      created_availabilities)
    local_time_zone = Time.zone || 'UTC'

    (start_date..end_date).each do |date|
      availability_start = Time.zone.local(date.year, date.month, date.day, start_hour, start_minute)
      availability_end = Time.zone.local(date.year, date.month, date.day, end_hour, end_minute)

      next unless availability_end > availability_start

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
