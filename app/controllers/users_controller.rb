class UsersController < ApplicationController
  def index
    # references the user in the params, NOT NECESSARILY THE CURRENT USER
    # current user will be referenced by current_user, not @user
    @users = User.all
  end

  def show
    # user profile page, can be any user referenced not just current user, see above comments
    authorize @user
    @user = User.find(params[:id])
  end

  def dashboard
    @user = current_user
  end
end
