class PagesController < ApplicationController
  skip_before_action :authenticate_user!
  def home
    @user = current_user
    @users = User.all
  end
end
