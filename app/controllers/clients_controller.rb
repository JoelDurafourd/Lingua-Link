class ClientsController < ApplicationController
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
  end

  def set_client
    @client = Client.find(params[:id])
  end
end
