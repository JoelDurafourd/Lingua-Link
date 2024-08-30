require 'line/bot' # gem 'line-bot-api'

class MessagesController < ApplicationController
  before_action :set_client

  # Skip CSRF protection for webhook
  skip_before_action :verify_authenticity_token, only: %i[callback update_all_users_rich_menu test_push_message]

  # Skip Devise authentication for webhook (if you're using Devise)
  skip_before_action :authenticate_user!, only: %i[callback update_all_users_rich_menu test_push_message]

  # Skip Pundit authorization check for webhook
  skip_after_action :verify_authorized, only: %i[callback update_all_users_rich_menu test_push_message]

  # Optionally, skip policy scope check if you're using it
  skip_after_action :verify_policy_scoped, only: %i[callback update_all_users_rich_menu test_push_message]

  def callback
    body = request.body.read
    signature = request.env['HTTP_X_LINE_SIGNATURE']

    unless @line_service.validate_signature(body, signature)
      head :bad_request
      return
    end

    events = @line_service.parse_events_from(body)
    line_menu_service = LineService::Menu.new(@line_service)

    line_menu_service.handle_events(events)

    head :ok
  end

  def test_push_message
    line_id = params[:line_id]
    json_body = request.body.read

    json_parse = JSON.parse(json_body, symbolize_names: true)

    # Assuming you have a service that handles pushing messages
    result = @line_service.push_message(line_id, json_parse)

    if result.present?
      render json: { status: 'success', message: 'Message pushed successfully' }, status: :ok
    else
      render json: { status: 'error', message: result.error_message }, status: :unprocessable_entity
    end
  end

  private

  def set_client
    @line_service = LineService::Client.new
  end
end
