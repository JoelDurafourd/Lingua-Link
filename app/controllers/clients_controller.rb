class ClientsController < ApplicationController
  include LineBotConcern

  def index
    @user = User.find(params[:user_id])
    if params[:user_id]
      @clients = Client.joins(:bookings).where(bookings: { user_id: params[:user_id] }).distinct
    else
      @clients = Client.all
    end
    @clients = policy_scope(@clients)
  end

  def show
    @client = Client.find(params[:id])
    authorize @client
    @user = User.find(params[:user_id])
    @note = Note.new
    @client_notes = @client.notes.order(created_at: :desc).first(3)
    # @line_client = @line_service.get_profile(@client.lineid)
  end

  def edit
    # find the client to edit
    @client = Client.find(params[:id])
    @user = User.find(params[:user_id])
    authorize @client
  end

  def update
    # update using security params below
    @client = Client.find(params[:id])
    @user = User.find(params[:user_id])
    authorize @client
    if @client.update(client_params)
      # if the current client is saved succesfully, redirect to the client page
      redirect_to dashboard_path(@user)
    else
      # else display an error message
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_user
    @user = User.find(params[:user_id])
  end

  # def set_client
  #   @client = @user.clients.find(params[:id])
  # end

  def client_params
    params.require(:client).permit(:lineid, :phone_number, :name, :nickname)
  end
end
