class ChatChannel < ApplicationCable::Channel
  def subscribed
    stream_from "chat_channel"
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
