module ActionCableHelper
  def broadcast_to_chat_room(client_id, teacher_id, message_id, message_sender, message_text, is_teacher: false)
    room_id = "chat_room_#{Utilities.generate_room_id(client_id, teacher_id)}"

    ActionCable.server.broadcast(
      room_id,
      {
        sender: message_sender,
        is_teacher:,
        message_id:,
        message: message_text,
        user_id: teacher_id,
        client_id:
      }
    )
  end
end
