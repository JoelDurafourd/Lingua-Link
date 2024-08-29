class ChatChannel < ApplicationCable::Channel
  def subscribed
    room_id = params[:room_id]
    stream_from "chat_room_#{room_id}"
    logger.info "Subscribed to chat_room_#{room_id}"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

  def get_user_data
    data = {
      id: current_user.id,
      email: current_user.email
    }

    ActionCable.server.broadcast("chat_channel", data)
  end
end
