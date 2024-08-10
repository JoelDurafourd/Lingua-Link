class ChatController < ApplicationController
  include LineBotConcern

  # Skip Pundit authorization checks for the index action
  skip_after_action :verify_policy_scoped, only: %i[index show send_message]
  skip_after_action :verify_authorized, only: %i[index show send_message]

  def index
  end

  def show
    # Find the selected client based on the :client_id parameter
    @client = Client.find_by(id: params[:client_id])

    return unless @client.nil?

    flash[:alert] = "Client not found or you do not have access to this client."
    # redirect_to root_path

    # Any additional logic you want to add for the index view
  end

  def send_message
    puts params
    first_name = current_user.first_name
    client_obj = Client.find_by(id: params[:to])
    line_id = client_obj.lineid
    puts "LINE ID: #{line_id}"
    teacher_id = first_name
    user_id = line_id
    message_text = params[:message]

    message = {
      type: "text",
      text: "#{teacher_id}: #{message_text}"
    }

    client.push_message(user_id, message)

    # Broadcast the message to the ActionCable channel
    ActionCable.server.broadcast(
      "chat_channel",
      {
        from: teacher_id,
        message: message_text
      }
    )

    # Respond with a JSON response
    render json: { status: "Message sent", message: message_text }, status: :ok
  end
end
