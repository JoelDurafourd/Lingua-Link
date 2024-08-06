# app/controllers/concerns/line_bot_concern.rb
require 'line/bot' # gem 'line-bot-api'

module LineBotConcern
  extend ActiveSupport::Concern

  included do
    before_action :set_client
  end

  # Dummy data structures
  TEACHERS = [
    { id: 1, name: 'Alice', subject: 'English Grammar' },
    { id: 2, name: 'Bob', subject: 'Conversation Skills' },
    { id: 3, name: 'Carol', subject: 'Business English' }
    # { id: 4, name: 'George', subject: 'Native English' }
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

    return unless data.start_with?('select_teacher_')

    teacher_id = data.split('_').last.to_i
    USERS[user_id] ||= {}
    USERS[user_id][:current_teacher_id] = teacher_id

    teacher = TEACHERS.find { |t| t[:id] == teacher_id }
    message = {
      type: 'text',
      text: "You're now chatting with Teacher #{teacher[:name]}. Your messages will be sent to this teacher."
    }
    client.reply_message(event['replyToken'], message)
  end

  def handle_message(event)
    user_id = event['source']['userId']
    text = event['message']['text']

    user = USERS[user_id]
    if user && user[:current_teacher_id]
      teacher = TEACHERS.find { |t| t[:id] == user[:current_teacher_id] }
      teacher_reply = reply_to_message(teacher, text)
      full_message = "[From Teacher #{teacher[:name]}] #{teacher_reply}"

      message = {
        type: 'text',
        text: full_message
      }
      client.reply_message(event['replyToken'], message)
    else
      message = {
        type: 'text',
        text: "Please select a teacher from the menu before sending a message."
      }
      return client.reply_message(event['replyToken'], message)
    end
  end

  def update_user_rich_menu(user_id)
    # Unlink any existing rich menu
    begin
      client.unlink_user_rich_menu(user_id)
    rescue Line::Bot::API::Error => e
      Rails.logger.info "No existing rich menu to unlink for user #{user_id}: #{e.message}"
    end

    # Delete any existing rich menu for this user
    existing_menu_id = USERS[user_id]&.[](:rich_menu_id)
    if existing_menu_id
      begin
        client.delete_rich_menu(existing_menu_id)
      rescue Line::Bot::API::Error => e
        Rails.logger.error "Error deleting rich menu #{existing_menu_id} for user #{user_id}: #{e.message}"
      end
    end

    # Create and link the new rich menu
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

    # Create an area for each teacher assigned to the user
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

      # Generate and upload the rich menu image
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
    # Constants for image dimensions
    width = 2500
    height = 1686
    rect_height = height / user_teachers.size
    padding = 20 # Padding between rectangles

    # Create a new image with the specified dimensions
    img = Magick::Image.new(width, height)
    img.background_color = 'white'

    # Create a drawing object
    gc = Magick::Draw.new
    gc.font = 'Arial'
    gc.pointsize = 36
    gc.fill = 'black'
    gc.stroke = 'black'
    gc.stroke_width(2)

    # Loop through each teacher and create a rectangle with the teacher's name
    user_teachers.each_with_index do |teacher_id, index|
      teacher = TEACHERS.find { |t| t[:id] == teacher_id }
      # Calculate rectangle position
      top_y = (index * rect_height) + padding
      bottom_y = ((index + 1) * rect_height) - padding

      # Draw the rectangle
      gc.fill(random_pastel_color) # Rectangle fill color
      gc.rectangle(padding, top_y, width - padding, bottom_y)

      # Calculate text position
      text_x = width / 2
      text_y = (top_y + bottom_y) / 2

      # Draw the teacher's name centered in the rectangle
      gc.fill_color('black')
      gc.fill = 'black' # Set text color again (in case it was overridden)
      gc.font_size(72)
      gc.text(text_x, text_y, teacher[:name]) # Directly set text position

      # Temporary Placeholder for calculations
      subject_metrics = gc.get_type_metrics(teacher[:subject])
      gc.text(text_x - (subject_metrics.width / 2) - 65, text_y + 75, teacher[:subject])
    end

    # Draw everything onto the image
    gc.draw(img)

    # Save the image to a file
    img.write('rich_menu_image.png')

    # Optionally, return the image object
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
