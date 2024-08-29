require 'digest'
require 'base64'

class ChatController < ApplicationController
  include ActionCableHelper
  include LineBotConcern

  # Skip Pundit authorization checks for the index action
  skip_after_action :verify_policy_scoped, only: %i[index show send_message]
  skip_after_action :verify_authorized, only: %i[index show send_message]

  def index
  end

  def show
    @client = Client.find_by(id: params[:id])
    @room_id = Utilities.generate_room_id(@client.id, current_user.id)
    @line_client = @line_service.get_profile(@client.lineid)
    @messages = current_user.messages.where(client_id: @client.id).order(created_at: :asc)
  end

  # line_message
  # message
  # action_message

  def send_message
    # Teacher Information
    teacher_obj = current_user

    teacher_first_name = teacher_obj.first_name
    teacher_last_name = teacher_obj.last_name

    Rails.logger.info(params[:to])
    # Client Information
    client_obj = Client.find_by(id: params[:to])

    client_line_id = client_obj.lineid

    message_uuid = SecureRandom.uuid
    message_text = params[:message].to_s.strip

    translate = Google::Cloud::Translate::V2.new(
      key: ENV.fetch("GOOGLE_TRANSLATE_API_KEY")
    )

    client_message = message_text

    client_message = translate.translate(message_text, to: client_obj.language).text if client_obj.enable_translations?

    # Save the message to the database
    Message.create!(
      uuid: message_uuid,
      sender: teacher_first_name,
      user_id: teacher_obj.id, # TeacherID
      client_id: client_obj.id, # ClientID
      contents: message_text
    )

    items = []

    line_message = {
      type: "text",
      text: client_message.to_s,
      sender: {
        name: teacher_first_name.to_s,
        iconUrl: teacher_obj.photo.url
      },
      quickReply: {
        items:
      }
    }

    if client_obj.chatting_with_teacher?(teacher_obj.id)
      items << LineService::Actions.chat_action(
        "End Chat",
        LineService::Actions.end_chat,
        "https://www.svgrepo.com/show/1113/inkwell.svg"
      )
    elsif client_obj.chatting_with_another_teacher?(teacher_obj.id)
      items.push(
        LineService::Actions.chat_action(
          "Start Chat",
          LineService::Actions.start_chat(teacher_obj.id),
          "https://www.svgrepo.com/show/1113/inkwell.svg"
        ),
        LineService::Actions.chat_action(
          "End Current Chat",
          LineService::Actions.end_chat,
          "https://www.svgrepo.com/show/1113/inkwell.svg"
        )
      )
    else
      items << LineService::Actions.chat_action(
        "Start Chat",
        LineService::Actions.start_chat(teacher_obj.id),
        "https://www.svgrepo.com/show/1113/inkwell.svg"
      )
    end

    @line_service.push_message(client_line_id, line_message)

    broadcast_to_chat_room(client_obj.id, current_user.id, message_uuid, teacher_first_name, message_text, is_teacher: true)

    # Respond with a JSON response
    render json: { status: "Message sent", message: message_text }, status: :ok
  end
end
