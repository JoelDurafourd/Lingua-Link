class AvailabilitiesController < ApplicationController
  def index
    # Fetch the current date or use the provided start_date parameter
    start_date = params.fetch(:start_date, Date.today).to_date

    # Query availabilitys for the current month, adjusting the range to cover the entire month
    @availabilitys = Availability.where(start_time: start_date.beginning_of_month..start_date.end_of_month)
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
    # creates a new availability based on provided inputs, it uses private security params below.
    @availability = Availability.new(availability_params.merge(user: current_user))
    @user = current_user
    authorize @availability
    # assigns current user to the availability
    if @availability.save
      # if the current availability is created succesfully, redirect to the avialability it was booked from
      redirect_to dashboard_path(current_user), notice: 'Availability successfully created!'
    else
      # else display an error message
      render :new, status: :unprocessable_entity
    end
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
