class PagesController < ApplicationController
  include Pundit
    skip_after_action :verify_authorized, only: [:home]

    skip_before_action :authenticate_user!, only: [:home]

  def home
  end

  # even though there is no defined index, removing this line will cause the website to break because pundit is expecting an index in the pages controller.
  # DO NOT REMOVE unless you are prepared to code out the pundit except in ApplicationController
  def index
  end
end
