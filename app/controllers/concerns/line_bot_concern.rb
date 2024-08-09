# app/controllers/concerns/line_bot_concern.rb
require 'line/bot'

module LineBotConcern
  extend ActiveSupport::Concern

  included do
    before_action :set_client
  end

  TEACHERS = [
    { id: 1, name: 'Alice', subject: 'English Grammar' },
    { id: 2, name: 'Bob', subject: 'Conversation Skills' },
    { id: 3, name: 'Carol', subject: 'Business English' }
  ]

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

    teacher = TEACHERS.find { |t| t[:id] == teacher_id }
    message = {
      type: 'text',
      text: "You're now chatting with Teacher #{teacher[:name]}. Your messages will be sent to this teacher.\n\nHow can I help you today?\nPlease select your preferred number below.\n1. lesson reservation, change, or cancellation\n2. confirm your reserved lesson\n3. other"
    }

    Rails.logger.info "Sending reply message: #{message[:text]}"

    begin
      response = client.reply_message(event['replyToken'], message)
      Rails.logger.info "Reply sent successfully: #{response.body}"
    rescue => e
      Rails.logger.error "Error sending reply: #{e.message}"
    end
  end

  def handle_message(event)
    user_id = event['source']['userId']
    text = event['message']['text']

    USERS[user_id] ||= {}

    response = case USERS[user_id][:state]
                when :awaiting_slot_selection
                  handle_slot_selection(user_id, text)
                when :awaiting_change_selection
                  handle_change_selection(user_id, text)
                when :awaiting_cancel_selection
                  handle_cancel_selection(user_id, text)
                else
                  handle_general_message(user_id, text)
                end

    message = { type: 'text', text: response }
    client.reply_message(event['replyToken'], message)
  end

  def handle_general_message(user_id, text)
    USERS[user_id] ||= {}

    case text
    when '1'
      handle_booking_request('1', user_id)
    when '2'
      "Here are your current reservations: [Display reservation list]"
    when '3'
      "Please tell us how else we can assist you."
    else
      if text.downcase.include?('reservation')
        handle_booking_request(text, user_id)
      else
        handle_teacher_message(user_id, text)
      end
    end
  end

  def handle_teacher_message(user_id, text)
    user = USERS[user_id]
    if user && user[:current_teacher_id]
      teacher = TEACHERS.find { |t| t[:id] == user[:current_teacher_id] }
      teacher_reply = reply_to_message(teacher, text)
      "[From Teacher #{teacher[:name]}] #{teacher_reply}"
    else
      "Please select a teacher from the menu before sending a message."
    end
  end

def handle_booking_request(message, user_id)
  case message
  when '1'
    "Please let us know your reservation request by choosing a number:\n1. New reservation\n2. Change reservation\n3. Cancel reservation\n\nPlease reply with the number of your choice (1, 2, or 3)."
  when '2'
    show_existing_reservations(user_id, :change)
  when '3'
    show_existing_reservations(user_id, :cancel)
  else
    case message
    when '1'
      show_available_slots(user_id)
    when '2'
      show_existing_reservations(user_id, :change)
    when '3'
      show_existing_reservations(user_id, :cancel)
    else
      "Invalid selection. Please choose 1 for new reservation, 2 for changing a reservation, or 3 for canceling a reservation."
    end
  end
end

def handle_booking_request(message, user_id)
  case message
  when '1'
    "Please let us know your reservation request by choosing a number:\n1. New reservation\n2. Change reservation\n3. Cancel reservation\n\nPlease reply with the number of your choice (1, 2, or 3)."
  when '2'
    show_existing_reservations(user_id, :change)
  when '3'
    show_existing_reservations(user_id, :cancel)
  else
    case message
    when '1'
      show_available_slots(user_id)
    when '2'
      show_existing_reservations(user_id, :change)
    when '3'
      show_existing_reservations(user_id, :cancel)
    else
      "Invalid selection. Please choose 1 for new reservation, 2 for changing a reservation, or 3 for canceling a reservation."
    end
  end
end

  def show_existing_reservations(user_id, action)
    user_reservations = Reservation.get_reservations_for_user(user_id)

    if user_reservations.any?
      message = "User B's reservations are as follows:\n"
      user_reservations.each_with_index do |reservation, index|
        message += "#{index + 1}. #{reservation.strftime('%m/%d %H:%M')}\n"
      end
      message += "\nPlease choose the number of the reservation you want to #{action}."

      USERS[user_id][:state] = action == :change ? :awaiting_change_selection : :awaiting_cancel_selection
      USERS[user_id][:user_reservations] = user_reservations
    else
      message = "You don't have any existing reservations."
    end

    message
  end

  def handle_slot_selection(user_id, text)
    slot_index = text.to_i - 1
    if slot_index.between?(0, USERS[user_id][:available_slots].length - 1)
      selected_slot = USERS[user_id][:available_slots][slot_index]
      # ここで予約を作成する処理を実装
      USERS[user_id][:state] = nil
      "Your reservation for #{selected_slot.strftime('%m/%d %H:%M')} has been confirmed."
    else
      "Invalid selection. Please choose a number from the list of available slots."
    end
  end

  def handle_change_selection(user_id, text)
    reservation_index = text.to_i - 1
    if reservation_index.between?(0, USERS[user_id][:user_reservations].length - 1)
      selected_reservation = USERS[user_id][:user_reservations][reservation_index]
      # ここで予約変更のプロセスを開始する
      USERS[user_id][:state] = :awaiting_new_slot
      USERS[user_id][:reservation_to_change] = selected_reservation
      show_available_slots(user_id)
    else
      "Invalid selection. Please choose a number from the list of your reservations."
    end
  end

  def handle_cancel_selection(user_id, text)
    reservation_index = text.to_i - 1
    if reservation_index.between?(0, USERS[user_id][:user_reservations].length - 1)
      selected_reservation = USERS[user_id][:user_reservations][reservation_index]
      # ここで予約をキャンセルする処理を実装
      USERS[user_id][:state] = nil
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

    user_teachers = USERS[user_id]&.[](:teachers) || TEACHERS.map { |t| t[:id] }

    rich_menu = {
      size: { width: 2500, height: 1686 },
      selected: true,
      name: "Teacher Selection Menu for User #{user_id}",
      chatBarText: "Select Teacher",
      areas: []
    }

    user_teachers.each_with_index do |teacher_id, index|
      teacher = TEACHERS.find { |t| t[:id] == teacher_id }
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
      teacher = TEACHERS.find { |t| t[:id] == teacher_id }
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

      subject_metrics = gc.get_type_metrics(teacher[:subject])
      gc.text(text_x - (subject_metrics.width / 2) - 65, text_y + 75, teacher[:subject])
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
    client
  end

  def random_pastel_color
    r = rand(128..255)
    g = rand(128..255)
    b = rand(128..255)
    format("#%02x%02x%02x", r, g, b)
  end

  def reply_to_message(teacher, _message)
    case teacher[:name]
    when 'Alice'
      "Grammar tip: Remember to capitalize proper nouns."
    when 'Bob'
      "Great! Can you elaborate on that point?"
    when 'Carol'
      "In a business context, we might phrase that as: 'optimize the workflow'."
    else
      "Thank you for your message."
    end
  end
end
