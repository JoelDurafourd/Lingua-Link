require 'line/bot' # gem 'line-bot-api'

# Define the file path where user IDs will be stored ### REMOVE LATER <-----
USER_IDS_FILE = Rails.root.join('storage', 'user_ids.txt') unless defined?(USER_IDS_FILE)


class MessagesController < ApplicationController
  include LineBotConcern

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

    Rails.logger.info "Received LINE webhook callback"
    Rails.logger.info "Body: #{body}"
    Rails.logger.info "Signature: #{signature}"

    unless client.validate_signature(body, signature)
      head :bad_request
      return
    end

    events = client.parse_events_from(body)
    events.each do |event|
      case event
      when Line::Bot::Event::Message
        case event.type
        when Line::Bot::Event::MessageType::Text
          handle_message(event)
        end
      when Line::Bot::Event::Postback
        handle_postback(event)
      when Line::Bot::Event::Follow
        handle_follow(event)
      end
    end

    head :ok
  end

  # Debug route for testing Rich Menu Update(s)
  def update_all_users_rich_menu
    user_ids = load_user_ids

    user_ids.each do |user_id|
      # Re-assign teachers to user. For simplicity, let's assign all teachers.
      assigned_teacher_ids = TEACHERS.map { |t| t[:id] }

      # Update the USERS hash with the assigned teachers
      USERS[user_id] ||= {}
      USERS[user_id][:teachers] = assigned_teacher_ids

      update_user_rich_menu(user_id)
    end
    render json: { message: "Rich menu updated for all users" }, status: :ok
  end

  private

  def load_user_ids
    FileUtils.touch(USER_IDS_FILE) unless File.exist?(USER_IDS_FILE)

    File.read(USER_IDS_FILE).split("\n").uniq
  end

  def save_user_id(user_id)
    if user_id_exists?(user_id)
      Rails.logger.info "User ID #{user_id} already exists in the file."
    else
      File.open(USER_IDS_FILE, 'a') do |file|
        file.puts(user_id)
      end
    end
  end

  def user_id_exists?(user_id)
    user_ids = load_user_ids
    user_ids.include?(user_id)
  end

  def handle_follow(event)
    user_id = event['source']['userId']
    USERS[user_id] = { teachers: TEACHERS.map { |t| t[:id] } }

    # Save the user ID to the file
    save_user_id(user_id)

    update_user_rich_menu(user_id)

    welcome_message = {
      type: 'text',
      text: "Welcome! You've been assigned to all our teachers. Use the menu at the bottom to select a teacher and start chatting!"
    }
    client.reply_message(event['replyToken'], welcome_message)
  end
end
#   def bot_answer_to(message, user_name)
#     # Existing code
#     elsif message.downcase.include?('reservation')
#       handle_booking_request(message, user_name)

#     # Existing code
#   end

#   # Add methods for creating, changing, and canceling reservations
# end
