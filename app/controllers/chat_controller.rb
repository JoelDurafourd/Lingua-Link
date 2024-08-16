class ChatController < ApplicationController
  include LineBotConcern

  # Skip Pundit authorization checks for the index action
  skip_after_action :verify_policy_scoped, only: %i[index show send_message]
  skip_after_action :verify_authorized, only: %i[index show send_message]

  def index
  end

  def show
    @client = Client.find_by(id: params[:id])
    @line_client = @line_service.get_profile(@client.lineid)
    @messages = Message.where(client_id: @client.id).order(created_at: :asc)
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

    translation = translate.translate(message_text, to: "ja")
    translated_message = translation.text

    # Save the message to the database
    Message.create!(
      uuid: message_uuid,
      sender: teacher_first_name,
      user_id: teacher_obj.id, # TeacherID
      client_id: client_obj.id, # ClientID
      contents: message_text
    )

    line_message = {
      type: "text",
      text: "#{teacher_first_name}: #{translated_message}"
    }

    @line_service.push_message(client_line_id, line_message)

    # Broadcast the message to the ActionCable channel
    ActionCable.server.broadcast(
      "chat_channel",
      {
        message_id: message_uuid,
        is_teacher: true,
        sender: teacher_first_name,
        user_id: teacher_obj.id,
        client_id: client_obj.id,
        message: message_text
      }
    )

    # Respond with a JSON response
    render json: { status: "Message sent", message: message_text }, status: :ok
  end
end
