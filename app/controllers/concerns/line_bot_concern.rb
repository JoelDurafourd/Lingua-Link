# app/controllers/concerns/line_bot_concern.rb
require 'line/bot'
require 'google/cloud/translate'

module LineBotConcern
  extend ActiveSupport::Concern

  included do
    before_action :set_client
    before_action :set_teachers
    before_action :set_translate_client
  end

  module UserState
    INITIAL = 0
    AWAITING_BOOKING_TYPE = 1
    AWAITING_SLOT_SELECTION = 2
    AWAITING_CHANGE_SELECTION = 3
    AWAITING_CANCEL_SELECTION = 4
    AWAITING_NEW_SLOT = 5
  end

  def set_teachers
    # Fetch all users from the database
    users = User.all

    # Map the users to the TEACHERS array format
    @teachers = users.map do |user|
      {
        id: user.id,
        name: user.first_name.to_s[0, 15]
      }
    end

    # Return the @teachers array
    @teachers
  end

  USERS = {}

  def client
    Rails.logger.info "LINE API Client"
    @client ||= Line::Bot::Client.new do |config|
      config.channel_secret = ENV.fetch('LINE_CHANNEL_SECRET', nil)
      config.channel_token = ENV.fetch('LINE_CHANNEL_TOKEN', nil)
    end
  end

  def handle_postback(event)
    user_id = event['source']['userId']
    data = event['postback']['data']

    Rails.logger.info "Handling postback for user #{user_id} with data: #{data}"

    return unless data.start_with?('select_teacher_')

    USERS[user_id] ||= {}
    teacher_id = data.split('_').last.to_i
    USERS[user_id][:current_teacher_id] = teacher_id

    teacher = @teachers.find { |t| t[:id] == teacher_id }
    message = {
      type: 'text',
      text: "You're now chatting with Teacher #{teacher[:name]}. Your messages will be sent to this teacher.\n\nHow can I help you today?\nPlease select your preferred number below.\n1. lesson reservation, change, or cancellation\n2. confirm your reserved lesson\n3. other"
    }

    Rails.logger.info "Sending reply message: #{message[:text]}"

    begin
      response = client.reply_message(event['replyToken'], message)
      Rails.logger.info "Reply sent successfully: #{response.body}"
    rescue StandardError => e
      Rails.logger.error "Error sending reply: #{e.message}"
    end
  end

  # def push_message(user_id, messages, headers: {}, payload: {})
  #   channel_token_required

  #   messages = [messages] if messages.is_a?(Hash)

  #   endpoint_path = '/bot/message/push'
  #   payload = payload.merge({ to: user_id, messages: messages }).to_json
  #   post(endpoint, endpoint_path, payload, credentials.merge(headers))
  # end

  # def send_message
  #   teacher_id = "Bob"
  #   user_id = "Uaed0e1c7b5ab003fd89f2e08d6ac64a1"
  #   message = {
  #     type: "text",
  #     text: "#{teacher_id} Great! Can you elaborate on that point PUS MESSAGe?"
  #   }
  #   client.push_message(user_id, message)
  # end

  def handle_message(event)
    user = User.find_or_create_by_line_user_id(event['source']['userId'])
    text = event['message']['text']

    response = case user.state.to_sym
               when :awaiting_booking_type
                 handle_booking_request(text, user)
               when :awaiting_slot_selection
                 handle_slot_selection(user, text)
               else
                 handle_general_message(user, text)
               end

    translated_response = translate_message(response, user.language)
    message = { type: 'text', text: translated_response }
    client.reply_message(event['replyToken'], message)
  end

  def handle_new_slot_selection(user_id, text)
    slot_index = text.to_i - 1
    if slot_index.between?(0, USERS[user_id][:available_slots].length - 1)
      new_slot = USERS[user_id][:available_slots][slot_index]
      old_slot = USERS[user_id][:reservation_to_change]
      # Implement reservation change logic here
      USERS[user_id][:state] = UserState::INITIAL
      "Your reservation has been changed from #{old_slot.strftime('%m/%d %H:%M')} to #{new_slot.strftime('%m/%d %H:%M')}."
    else
      "Invalid selection. Please choose a number from the list of available slots."
    end
  end

  # def handle_message(event)
  #   user_id = event['source']['userId']
  #   text = event['message']['text']

  #   USERS[user_id] ||= {}

  #   # send_message
  #   user_state = USERS[user_id][:state]

  #   response = case user_state
  #              when :awaiting_slot_selection
  #                handle_slot_selection(user_id, text)
  #              when :awaiting_change_selection
  #                handle_change_selection(user_id, text)
  #              when :awaiting_cancel_selection
  #                handle_cancel_selection(user_id, text)
  #              else
  #                handle_general_message(user_id, text)
  #              end

  #   message = { type: 'text', text: response }
  #   client.reply_message(event['replyToken'], message)
  # end
  #

  def handle_teacher_message(user, text)
    if user.current_teacher
      teacher = user.current_teacher

      # ユーザーのメッセージを先生側への言語に翻訳
      translated_text = translate_message(text, teacher.language)

      ActionCable.server.broadcast(
        "chat_channel",
        {
          from: user.line_user_id,
          message: translated_text,
          original_message: text,
          from_language: user.language,
          to_language: teacher.language
        }
      )
      "Message sent to Teacher #{teacher.name}"
    else
      "Please select a teacher from the menu before sending a message."
    end
  end

  # def handle_teacher_message(user, text)
  #   if user.current_teacher_id
  #     teacher = @teachers.find { |t| t[:id] == user.current_teacher_id }
  #     ActionCable.server.broadcast(
  #       "chat_channel",
  #       {
  #         from: user.line_user_id,
  #         message: text
  #       }
  #     )
  #     "Message sent to Teacher #{teacher[:name]}"
  #   else
  #     "Please select a teacher from the menu before sending a message."
  #   end
  # end

  # def handle_general_message(user_id, text)
  #   USERS[user_id] ||= {}

  #   case text
  #   when '1'
  #     handle_booking_request('1', user_id)
  #   when '2'
  #     "Here are your current reservations: [Display reservation list]"
  #   when '3'
  #     "Please tell us how else we can assist you."
  #   else
  #     if text.downcase.include?('reservation')
  #       handle_booking_request(text, user_id)
  #     else
  #       handle_teacher_message(user_id, text)
  #     end
  #   end
  # end

  def handle_teacher_message(user_id, text)
    user = USERS[user_id]
    if user && user[:current_teacher_id]
      teacher = @teachers.find { |t| t[:id] == user[:current_teacher_id] }
      ActionCable.server.broadcast(
        "chat_channel",
        {
          from: user_id,
          message: text
        }
      )
      # teacher_reply = reply_to_message(teacher, text)
      # "[From Teacher #{teacher[:name]}] #{teacher_reply}"
    else
      "Please select a teacher from the menu before sending a message."
    end
  end

  def handle_booking_request(text, user)
    case text
    when '1'
      user.update(state: :awaiting_slot_selection)
      show_available_slots(user)
    when '2'
      user.update(state: :awaiting_change_selection)
      show_existing_reservations(user, :change)
    when '3'
      user.update(state: :awaiting_cancel_selection)
      show_existing_reservations(user, :cancel)
    else
      "Invalid selection. Please choose 1 for new reservation, 2 for changing a reservation, or 3 for canceling a reservation."
    end
  end

  def show_existing_reservations(user_id, action)
    user_reservations = Reservation.get_reservations_for_user(user_id)

    if user_reservations.any?
      message = "Your reservations are as follows:\n"
      user_reservations.each_with_index do |reservation, index|
        message += "#{index + 1}. #{reservation.strftime('%m/%d %H:%M')}\n"
      end
      message += "\nPlease choose the number of the reservation you want to #{action}."

      USERS[user_id][:user_reservations] = user_reservations
    else
      USERS[user_id][:state] = UserState::INITIAL
      message = "You don't have any existing reservations."
    end

    message
  end

  def handle_slot_selection(user, text)
    slot_index = text.to_i - 1
    available_slots = user.available_slots # このメソッドは User モデルに追加する必要があります
    if slot_index.between?(0, available_slots.length - 1)
      selected_slot = available_slots[slot_index]
      # ここで予約を作成する処理を実装
      user.update(state: :initial)
      "Your reservation for #{selected_slot.strftime('%m/%d %H:%M')} has been confirmed."
    else
      "Invalid selection. Please choose a number from the list of available slots."
    end
  end

  def handle_change_selection(user_id, text)
    reservation_index = text.to_i - 1
    if reservation_index.between?(0, USERS[user_id][:user_reservations].length - 1)
      selected_reservation = USERS[user_id][:user_reservations][reservation_index]
      USERS[user_id][:state] = UserState::AWAITING_NEW_SLOT
      USERS[user_id][:reservation_to_change] = selected_reservation
      show_available_slots(user_id)
    else
      "Invalid selection. Please choose a number from the list of your reservations."
    end
  end

  def show_available_slots(user_id)
    # Implement logic to fetch and display available slots
    available_slots = [Time.now + 1.day, Time.now + 2.days, Time.now + 3.days] # Example slots
    USERS[user_id][:available_slots] = available_slots

    message = "Available slots:\n"
    available_slots.each_with_index do |slot, index|
      message += "#{index + 1}. #{slot.strftime('%m/%d %H:%M')}\n"
    end
    message += "\nPlease choose the number of the slot you want to reserve."
  end

  def handle_cancel_selection(user_id, text)
    reservation_index = text.to_i - 1
    if reservation_index.between?(0, USERS[user_id][:user_reservations].length - 1)
      selected_reservation = USERS[user_id][:user_reservations][reservation_index]
      # Implement reservation cancellation logic here
      USERS[user_id][:state] = UserState::INITIAL
      "Your reservation for #{selected_reservation.strftime('%m/%d %H:%M')} has been cancelled."
    else
      "Invalid selection. Please choose a number from the list of your reservations."
    end
  end

  def update_user_rich_menu(user_id)
    begin
      client.unlink_user_rich_menu(user_id)
    rescue Line::Bot::API::Error => e
      Rails.logger.info "No existing rich menu to unlink for user #{user_id}: #{e.message}"
    end

    existing_menu_id = USERS[user_id]&.[](:rich_menu_id)
    if existing_menu_id
      begin
        client.delete_rich_menu(existing_menu_id)
      rescue Line::Bot::API::Error => e
        Rails.logger.error "Error deleting rich menu #{existing_menu_id} for user #{user_id}: #{e.message}"
      end
    end

    rich_menu_id = create_teacher_rich_menu(user_id)

    if rich_menu_id
      client.link_user_rich_menu(user_id, rich_menu_id)
      USERS[user_id][:rich_menu_id] = rich_menu_id
      Rails.logger.info "Successfully linked rich menu #{rich_menu_id} to user #{user_id}"
    else
      Rails.logger.error "Failed to create or link rich menu for user #{user_id}"
    end

    rich_menu_id
  end

  def create_teacher_rich_menu(user_id)
    require 'tempfile'

    user_teachers = USERS[user_id]&.[](:teachers) || @teachers.map { |t| t[:id] }

    rich_menu = {
      size: { width: 2500, height: 1686 },
      selected: true,
      name: "Teacher Selection Menu for User #{user_id}",
      chatBarText: "Select Teacher",
      areas: []
    }

    user_teachers.each_with_index do |teacher_id, index|
      teacher = @teachers.find { |t| t[:id] == teacher_id }
      rich_menu[:areas] << {
        bounds: {
          x: 0,
          y: 562 * index,
          width: 2500,
          height: 562
        },
        action: {
          type: "postback",
          data: "select_teacher_#{teacher[:id]}",
          label: "Chat with #{teacher[:name]}"
        }
      }
    end

    Rails.logger.debug "Attempting to create rich menu for user #{user_id} with payload: #{rich_menu.to_json}"

    response = client.create_rich_menu(rich_menu)

    if response.is_a?(Net::HTTPSuccess)
      rich_menu_id = JSON.parse(response.body)['richMenuId']
      Rails.logger.info "Successfully created rich menu with ID: #{rich_menu_id} for user #{user_id}"

      image_blob = generate_rich_menu_image(user_teachers)

      Rails.logger.debug "Attempting to upload rich menu image for user #{user_id}"

      begin
        temp_file = Tempfile.new(['rich_menu', '.png'])
        temp_file.binmode
        temp_file.write(image_blob)
        temp_file.rewind

        image_response = client.create_rich_menu_image(rich_menu_id, temp_file)

        if image_response.is_a?(Net::HTTPSuccess)
          Rails.logger.info "Successfully uploaded image for rich menu ID: #{rich_menu_id}"
          rich_menu_id
        else
          Rails.logger.error "Failed to upload rich menu image: #{image_response.code} #{image_response.message}"
          Rails.logger.error "Response body: #{image_response.body}"
          delete_rich_menu(rich_menu_id)
          nil
        end
      rescue StandardError => e
        Rails.logger.error "Exception while uploading rich menu image: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        delete_rich_menu(rich_menu_id)
        nil
      ensure
        temp_file.close
        temp_file.unlink
      end
    else
      Rails.logger.error "Failed to create rich menu: #{response.code} #{response.message}"
      Rails.logger.error "Response body: #{response.body}"
      nil
    end
  end

  def generate_rich_menu_image(user_teachers)
    width = 2500
    height = 1686
    rect_height = height / user_teachers.size
    padding = 20

    img = Magick::Image.new(width, height)
    img.background_color = 'white'

    gc = Magick::Draw.new
    gc.font = 'Arial'
    gc.pointsize = 36
    gc.fill = 'black'
    gc.stroke = 'black'
    gc.stroke_width(2)

    user_teachers.each_with_index do |teacher_id, index|
      teacher = @teachers.find { |t| t[:id] == teacher_id }
      top_y = (index * rect_height) + padding
      bottom_y = ((index + 1) * rect_height) - padding

      gc.fill(random_pastel_color)
      gc.rectangle(padding, top_y, width - padding, bottom_y)

      text_x = width / 2
      text_y = (top_y + bottom_y) / 2

      gc.fill_color('black')
      gc.fill = 'black'
      gc.font_size(72)
      gc.text(text_x, text_y, teacher[:name])

      # subject_metrics = gc.get_type_metrics(teacher[:subject])
      # gc.text(text_x - (subject_metrics.width / 2) - 65, text_y + 75, teacher[:subject])
    end

    gc.draw(img)

    img.write('rich_menu_image.png')

    img.format = 'PNG'
    img.to_blob
  end

  def delete_rich_menu(rich_menu_id)
    Rails.logger.info "Attempting to delete rich menu with ID: #{rich_menu_id}"
    begin
      response = client.delete_rich_menu(rich_menu_id)
      if response.is_a?(Net::HTTPSuccess)
        Rails.logger.info "Successfully deleted rich menu with ID: #{rich_menu_id}"
      else
        Rails.logger.error "Failed to delete rich menu: #{response.code} #{response.message}"
      end
    rescue StandardError => e
      Rails.logger.error "Exception while deleting rich menu: #{e.message}"
    end
  end

  def assign_teachers_to_user(user_id, teacher_ids)
    USERS[user_id] ||= {}
    USERS[user_id][:teachers] = teacher_ids
    update_user_rich_menu(user_id)
  end

  private

  def set_client
    @client ||= Line::Bot::Client.new do |config|
      config.channel_secret = ENV.fetch('LINE_CHANNEL_SECRET', nil)
      config.channel_token = ENV.fetch('LINE_CHANNEL_TOKEN', nil)
    end
  end

  def set_teachers
    @teachers = User.all.map do |user|
      {
        id: user.id,
        name: user.first_name.to_s[0, 15]
      }
    end
  end

  def random_pastel_color
    r = rand(128..255)
    g = rand(128..255)
    b = rand(128..255)
    format("#%02x%02x%02x", r, g, b)
  end

  def reply_to_message(teacher, message)
    ActionCable.server.broadcast(
      "chat_channel",
      {
        from: teacher[:name],
        message:
      }
    )
  end
  # case teacher[:name]
  # when 'Alice'
  #   "Grammar tip: Remember to capitalize proper nouns."
  # when 'Bob'
  #   "Great! Can you elaborate on that point?"

  # when 'Carol'
  #   "In a business context, we might phrase that as: 'optimize the workflow'."
  # else
  #   "Thank you for your message."
  # end

  def translate_message(text, target_language)
    source_language = @translate_client.detect(text)
    if source_language.language == target_language
      text
    else
      translation = @translate_client.translate(text, to: target_language)
      translation.text
    end
  end

  def set_translate_client
    @translate_client ||= Google::Cloud::Translate.translation_v2_service(
      credentials: JSON.parse(ENV.fetch('GOOGLE_APPLICATION_CREDENTIALS', nil))
    )
  end
end
