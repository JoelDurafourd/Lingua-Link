class RoomsController < ApplicationController
  # Skip Pundit authorization checks for the index action
  skip_after_action :verify_policy_scoped, only: :index
  skip_after_action :verify_authorized, only: :index

  def index
  end

  def show
  end
end
