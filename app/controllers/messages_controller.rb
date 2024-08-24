require 'line/bot' # gem 'line-bot-api'

# Define the file path where user IDs will be stored ### REMOVE LATER <-----
USER_IDS_FILE = Rails.root.join('storage', 'user_ids.txt') unless defined?(USER_IDS_FILE)

class MessagesController < ApplicationController
  before_action :set_client

  # Skip CSRF protection for webhook
  skip_before_action :verify_authenticity_token, only: %i[callback update_all_users_rich_menu]

  # Skip Devise authentication for webhook (if you're using Devise)
  skip_before_action :authenticate_user!, only: %i[callback update_all_users_rich_menu]

  # Skip Pundit authorization check for webhook
  skip_after_action :verify_authorized, only: %i[callback update_all_users_rich_menu]

  # Optionally, skip policy scope check if you're using it
  skip_after_action :verify_policy_scoped, only: %i[callback update_all_users_rich_menu]

  def callback
    body = request.body.read
    signature = request.env['HTTP_X_LINE_SIGNATURE']

    unless @line_service.validate_signature(body, signature)
      head :bad_request
      return
    end

    events = @line_service.parse_events_from(body)
    line_menu_service = LineMenuService.new(@line_service)

    line_menu_service.handle_events(events)

    head :ok
  end

  private

  def set_client
    @line_service = LineService.new
  end
end
