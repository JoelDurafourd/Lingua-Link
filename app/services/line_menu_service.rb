class LineMenuService
  attr_accessor :client, :online_translation, :redis, :menu_manager

  def initialize(client)
    @client = client
    @online_translation = TranslationService.new
    @redis = RedisService.new
    @menu_manager = MenuService.new
  end

  def handle_events(events)
    Rails.logger.info "Processing #{events.size} LINE events"

    events.each do |event|
      case event
      when Line::Bot::Event::Message
        handle_message(event)
      when Line::Bot::Event::Postback
        handle_postback(event)
      when Line::Bot::Event::Follow
        handle_follow(event)
      when Line::Bot::Event::Unfollow
        handle_unfollow(event)
      else
        Rails.logger.warn "Unhandled event type: #{event}"
      end
    end
  end

  def handle_unfollow(event)
    user_id = event['source']['userId']
    student = Client.find_by(lineid: user_id)

    if student
      # Destroy associated messages
      Message.where(client_id: student.id).destroy_all
      Booking.where(client_id: student.id).delete_all

      # Destroy associations with users (teachers)
      student.users.clear

      # Destroy the client record (student)
      student.destroy

      Rails.logger.info "Destroyed client #{user_id} and all associated data."
    else
      Rails.logger.warn "Client with lineid #{user_id} not found."
    end
  end

  # @param [Line::Bot::Event::Message] event
  def handle_message(event)
    source_data = event['source']
    message_data = event['message']

    ## Line Object -- START
    # Client (Line User)
    user_id = source_data['userId']
    user_profile = @client.get_profile(user_id)
    user_language = user_profile[:language].to_s

    # Message
    message_id = message_data['id']
    message_text = message_data['text']

    # Testing Debug Creation of RichMenu!
    if message_text == "DEBUG--BUILD-RICH-MENU"
      build_and_set_rich_menu
      message = {
        type: 'text',
        text: "Debug -- RichMenu has been created!"
      }
      return @client.reply_message(event['replyToken'], message)
    end

    # Other
    reply_token = event['replyToken']
    timestamp = event['timestamp']
    ## Line Object -- END

    client = Client.find_by(lineid: user_id)
    client_id = client.id
    client_user_chat_id = client.user_chat_id

    # If auto translation is enabled, translate the message
    # if client.enable_translations
    # user_profile[:language]
    message_text = @online_translation.translate(message_text, 'en')
    # end

    # Create Message Object
    message = Message.create!(
      message_id:,
      contents: message_text,
      sender: user_profile[:display_name],
      reply_token:,
      timestamp: Time.at(timestamp / 1000), # Convert timestamp to datetime
      client_id:,
      user_id: client_user_chat_id,
      uuid: SecureRandom.uuid
    )

    ActionCable.server.broadcast(
      "chat_channel",
      {
        message_id: message.uuid,
        is_teacher: false,
        sender: message.sender,
        message: message_text
      }
    )
  end

  def handle_postback(event)
    user_id = event['source']['userId']
    data = event['postback']['data']
    action, teacher_id, page = parse_postback_data(data)

    case action
    when 'chat_session_end'
      handle_chat_session_end(user_id, event)
    when 'book'
      handle_booking(teacher_id, user_id, event)
    when 'your_teachers'
      show_your_teachers(user_id, event)
    when 'find_teachers'
      find_teachers(user_id, event)
    when 'confirm_booking'
      handle_confirm_booking(user_id, event)
    when 'add_teacher'
      add_teacher_to_user(user_id, teacher_id, event)
    when 'pagination'
      find_teachers(user_id, event, page: page.to_i)
    when 'auto_translation'
      enable_auto_translation(user_id, event)
    when 'chat'
      handle_chat(user_id, teacher_id, event)

    when 'your_booking'
      _booking(user_id, event)

    when 'cancel_booking'
      cancel_booking(user_id, param, event)

      # else
      #   Rails.logger.error "Unknown postback action: #{action}"

    end
  end

  def handle_chat_session_end(user_id, event)
    client = Client.find_by(lineid: user_id)

    if client
      if client.user_chat_id.nil?
        Rails.logger.info "No active chat session for client #{client.id}"
        message = { type: 'text', text: "No active chat session to end." }
      else
        client.update(user_chat_id: nil)
        Rails.logger.info "Ended chat session for client #{client.id}"
        message = { type: 'text', text: "Chat session ended successfully." }
      end
      @client.reply_message(event['replyToken'], message)
    else
      Rails.logger.warn "Client with LINE ID #{user_id} not found"
      message = { type: 'text', text: "Client not found." }
      @client.reply_message(event['replyToken'], message)
    end
  end

  def handle_chat(user_id, teacher_id, event)
    client = Client.find_by(lineid: user_id)
    teacher = User.find_by(id: teacher_id)

    if client && teacher
      # Assign the current teacher to the client for chatting
      client.update(user_chat_id: teacher_id)
      Rails.logger.info "Chat initiated between client #{client.id} and teacher #{teacher.id}"

      # Respond to the user confirming the chat initiation
      message = {
        type: 'text',
        text: "You are now chatting with #{teacher.first_name} #{teacher.last_name}. How can they assist you today?"
      }
      @client.reply_message(event['replyToken'], message)
    else
      Rails.logger.error "Chat initiation failed: Client or Teacher not found."
      message = {
        type: 'text',
        text: "Unable to initiate chat. Please try again later."
      }
      @client.reply_message(event['replyToken'], message)
    end
  end

  def assign_chat_to_client(client, user_chat_id)
    client.update(user_chat_id:)
    Rails.logger.info "Assigned user_chat_id #{user_chat_id} to client #{client.id}"
  end

  def handle_confirm_booking(user_id, event)
    availability_id = extract_availability_id_from_postback(event)
    user_id = event['source']['userId']
    client = Client.find_by(lineid: user_id)

    if client && availability_id
      availability = Availability.find_by(id: availability_id)
      if availability

        booking = Booking.new(
          user_id: availability.user_id,
          client_id: client.id,
          start_time: availability.start_time,
          end_time: availability.end_time
        )

        if booking.save
          Rails.logger.info "Booking confirmed for client #{client.id} at #{availability.start_time}"

          confirmation_message = {
            type: "text",
            text: "Your booking for #{availability.start_time.strftime('%B %d, %Y - %I:%M %p')} has been confirmed."
          }

          @client.reply_message(event['replyToken'], confirmation_message)
        else
          Rails.logger.error "Booking not found"
        end

      else
        Rails.logger.error "Availability not found with ID #{availability_id}"
      end
    else
      Rails.logger.error "Client or Availability not found."
    end
  end

  def extract_availability_id_from_postback(event)
    postback_data = event['postback']['data']
    Rack::Utils.parse_nested_query(postback_data)['availability_id']
  end

  def add_teacher_to_user(user_id, teacher_id, event)
    teacher = User.find_by(id: teacher_id)
    student = Client.find_by(lineid: user_id)

    if student.users << teacher
      # Logic to add the teacher to the user's list
      Rails.logger.info "User #{user_id} added teacher #{teacher_id}."
    else
      Rails.logger.error "Teacher not found with ID #{teacher_id}."
    end
  end

  def show_your_teachers(user_id, event)
    Rails.logger.info "Displaying teachers for user #{user_id}."

    # Find the client (student) by lineid
    student = Client.find_by(lineid: user_id)

    if student.nil?
      Rails.logger.warn "Client with lineid #{user_id} not found."
      return
    end

    # Check if the client has any associated teachers
    if student.users.exists?
      # Display the carousel of teachers
      @client.reply_message(event['replyToken'], carousel_message(user_id))
    else
      # Send a message indicating no teachers are associated with the client
      no_teachers_message = {
        type: 'text',
        text: 'You currently have no teachers associated with your account.'
      }
      @client.reply_message(event['replyToken'], no_teachers_message)
    end
  end

  def find_teachers(user_id, event, page: 1)
    Rails.logger.info "Finding teachers for user #{user_id} on page #{page}."

    per_page = 5
    offset = (page - 1) * per_page

    # Find the student (client) by lineid
    student = Client.find_by(lineid: user_id)

    # Get the IDs of the teachers already associated with the student
    excluded_teacher_ids = student.users.pluck(:id)

    # Fetch teachers excluding the ones the student already has, with pagination
    teachers = User.where.not(id: excluded_teacher_ids).offset(offset).limit(per_page + 1) # Fetch one extra to check for next page

    # Create bubbles for the current page of teachers
    bubbles = teachers.first(per_page).map do |teacher|
      teacher_bubble_with_add_button(
        name: "#{teacher.first_name} #{teacher.last_name}",
        subject: "English", # Or dynamic if subject is stored in the User model
        image_url: "https://example.com/default_teacher_image.png", # Replace with actual image logic
        add_teacher_postback_data: "action=add_teacher&teacher_id=#{teacher.id}"
      )
    end

    # Add a pagination bubble if there are more teachers available
    bubbles << pagination_bubble(page + 1) if teachers.size > per_page

    # Create the carousel message
    message = {
      type: "flex",
      altText: "Here are some teachers you can add.",
      contents: {
        type: "carousel",
        contents: bubbles
      }
    }

    # Send the carousel message to the user
    response = @client.push_message(user_id, message)
    Rails.logger.info "Sent carousel message with #{bubbles.size} bubbles for user #{user_id} on page #{page} with response #{response}."
  end

  def teacher_bubble_with_add_button(name:, subject:, image_url:, add_teacher_postback_data:)
    {
      type: "bubble",
      hero: {
        type: "image",
        url: image_url,
        size: "full",
        aspectRatio: "20:13",
        aspectMode: "cover"
      },
      body: {
        type: "box",
        layout: "vertical",
        contents: [
          {
            type: "text",
            text: name,
            weight: "bold",
            size: "xl"
          },
          {
            type: "box",
            layout: "vertical",
            spacing: "sm",
            margin: "lg",
            contents: [
              {
                type: "box",
                layout: "baseline",
                contents: [
                  {
                    type: "text",
                    text: "Subject",
                    size: "sm",
                    color: "#AAAAAA",
                    flex: 2
                  },
                  {
                    type: "text",
                    text: subject,
                    size: "sm",
                    color: "#666666",
                    flex: 7,
                    wrap: true
                  }
                ]
              }
            ]
          }
        ]
      },
      footer: {
        type: "box",
        layout: "vertical",
        flex: 0,
        spacing: "sm",
        contents: [
          {
            type: "button",
            action: {
              type: "postback",
              label: "Add Teacher",
              data: add_teacher_postback_data,
              displayText: "Adding #{name} to your teachers"
            },
            height: "sm",
            style: "link"
          },
          {
            type: "spacer",
            size: "sm"
          }
        ]
      }
    }
  end

  def pagination_bubble(next_page)
    {
      type: "bubble",
      body: {
        type: "box",
        layout: "vertical",
        contents: [
          {
            type: "text",
            text: "More Teachers",
            weight: "bold",
            size: "xl",
            align: "center",
            contents: []
          }
        ]
      },
      footer: {
        type: "box",
        layout: "vertical",
        flex: 0,
        spacing: "sm",
        contents: [
          {
            type: "button",
            action: {
              type: "postback",
              label: "See More",
              data: "action=pagination&page=#{next_page}"
            },
            height: "sm",
            style: "link"
          },
          {
            type: "spacer",
            size: "sm"
          }
        ]
      }
    }
  end

  def enable_auto_translation(user_id, event)
    Rails.logger.info "Enabling auto translation for user #{user_id}."

    student = Client.find_by(lineid: user_id)

    if student.nil?
      message = {
        type: 'text',
        text: "User not found."
      }
      @client.reply_message(event['replyToken'], message)
      return
    end

    if student.toggle_translations!
      translation_status = student.enable_translations ? "enabled" : "disabled"

      message_text = "Auto translation has been #{translation_status}."

      message_text = @online_translation.t(message_text) if student.enable_translations

      message = {
        type: 'text',
        text: message_text
      }
    else
      message = {
        type: 'text',
        text: "There was an error updating your translation settings. Please try again."
      }
    end

    @client.reply_message(event['replyToken'], message)
  end

  def parse_postback_data(data)
    params = Rack::Utils.parse_nested_query(data)
    [params['action'], params['teacher_id'], params['page']]
  end

  def handle_booking(teacher_id, user_id, event)
    teacher = User.find_by(id: teacher_id)
    client = Client.find_by(lineid: user_id)

    if teacher && client
      Rails.logger.info "Booking request received for teacher #{teacher.id} - #{teacher.first_name} #{teacher.last_name}"

      # Fetch the teacher's availabilities, excluding those that overlap with the student's bookings
      booked_time_ranges = client.bookings.where(user_id: teacher.id).map do |booking|
        booking.start_time..booking.end_time
      end

      availabilities = teacher.availabilities.select do |availability|
        booked_time_ranges.none? do |range|
          range.overlaps?(availability.start_time..availability.end_time)
        end
      end.first(5)

      # Build the booking message dynamically based on the availabilities
      booking_options = availabilities.map do |availability|
        start_time = availability.start_time.strftime("%B %d, %Y - %I:%M %p")
        end_time = availability.end_time.strftime("%I:%M %p")
        {
          type: "box",
          layout: "horizontal",
          contents: [
            {
              type: "text",
              text: "#{start_time} to #{end_time}",
              size: "sm",
              color: "#666666",
              flex: 3,
              wrap: true
            },
            {
              type: "button",
              action: {
                type: "postback",
                label: "Book",
                data: "action=confirm_booking&availability_id=#{availability.id}"
              },
              height: "sm",
              style: "primary",
              flex: 1
            }
          ]
        }
      end

      if booking_options.any?
        booking_msg = {
          type: "flex",
          altText: "Available Booking Dates",
          contents: {
            type: "bubble",
            body: {
              type: "box",
              layout: "vertical",
              contents: [
                {
                  type: "text",
                  text: "Available Booking Dates",
                  weight: "bold",
                  size: "xl",
                  align: "center"
                },
                {
                  type: "box",
                  layout: "vertical",
                  spacing: "md",
                  margin: "lg",
                  contents: booking_options
                }
              ]
            }
          }
        }

        @client.reply_message(event['replyToken'], booking_msg)
      else
        # If no booking options are available
        no_availability_msg = {
          type: "text",
          text: "There are no available booking slots for this teacher at the moment."
        }
        @client.reply_message(event['replyToken'], no_availability_msg)
      end
    else
      Rails.logger.error "Teacher not found with ID #{teacher_id} or Client not found with lineid #{user_id}"
    end
  end

  def handle_follow(event)
    user_id = event['source']['userId']

    # Fetch user profile from LINE
    user_profile = @client.get_profile(user_id)
    display_name = user_profile[:display_name]
    user_language = user_profile[:language]

    # Check if the client already exists
    client = Client.find_or_initialize_by(lineid: user_id)

    if client.new_record?
      client.name = display_name
      client.phone_number = "" # Assuming phone_number is optional or blank by default
      client.language = user_language
      client.photo_url = user_profile[:picture_url]
      client.save!
      Rails.logger.info "New client created: #{client.inspect}"
    else
      Rails.logger.info "Existing client found: #{client.inspect}"
    end

    # Prepare and send the welcome message
    message = {
      type: 'text',
      text: "Welcome! You can start using Lingua-Link on your smartphone by selecting one of the menu options."
    }

    begin
      response = @client.reply_message(event['replyToken'], message)
      Rails.logger.info "Welcome message sent successfully to user #{user_id} with response #{response}"
    rescue StandardError => e
      Rails.logger.error "Error sending welcome message to user #{user_id}: #{e.message}"
    end
  end

  def create_rich_menu
    menu_01 = {
      size: {
        width: 2500,
        height: 1686
      },
      selected: true,
      name: "MainMenu",
      chatBarText: "Selection Men",
      areas: [
        {
          bounds: {
            x: 41,
            y: 54,
            width: 777,
            height: 785
          },
          action: {
            type: "postback",
            text: "Find Teachers",
            data: "action=find_teachers"
          }
        },
        {
          bounds: {
            x: 856,
            y: 860,
            width: 780,
            height: 780
          },
          action: {
            type: "postback",
            text: "Chat Session Ended",
            data: "action=chat_session_end"
          }
        },
        {
          bounds: {
            x: 1679,
            y: 860,
            width: 765,
            height: 780
          },
          action: {
            type: "postback",
            text: "action=auto_translation",
            data: "Auto Translation"
          }
        },
        {
          bounds: {
            x: 868,
            y: 45,
            width: 780,
            height: 780
          },
          action: {
            type: "postback",
            text: "Your Teachers",
            data: "action=your_teachers"
          }
        },
        {
          bounds: {
            x: 1679,
            y: 54,
            width: 780,
            height: 780
          },
          action: {
            type: "postback",
            text: "Your Booking",
            data: "action=your_booking"
          }
        }
      ]
    }

    response = @client.create_rich_menu(menu_01)

    if response.is_a?(Net::HTTPSuccess)
      response_body = JSON.parse(response.body)
      Rails.logger.info("Rich menu created successfully: #{response_body}")
      response_body
    else
      Rails.logger.error("Failed to create rich menu: #{response.code} - #{response.message}")
      nil
    end
  rescue JSON::ParserError => e
    Rails.logger.error("Failed to parse response body: #{e.message}")
    nil
  rescue StandardError => e
    Rails.logger.error("Unexpected error occurred: #{e.message}")
    nil
  end

  def build_and_set_rich_menu
    rich_menu = create_rich_menu
    return unless rich_menu

    rich_menu_id = rich_menu['richMenuId']

    upload_response = upload_rich_menu_image(rich_menu_id, 'll-richmenu-04.png')
    return unless upload_response

    def_response = @client.set_default_rich_menu(rich_menu_id)

    if def_response.is_a?(Net::HTTPSuccess)
      Rails.logger.info("Rich menu #{rich_menu_id} set as default successfully.")
      def_response.body
    else
      Rails.logger.error("Failed to set default rich menu: #{def_response.code} - #{def_response.message}")
      nil
    end
  end

  def upload_rich_menu_image(rich_menu_id, image_file_name)
    file_path = Rails.root.join('app', 'assets', 'images', image_file_name)
    url = "https://api-data.line.me/v2/bot/richmenu/#{rich_menu_id}/content"
    uri = URI.parse(url)

    request = Net::HTTP::Post.new(uri)
    request['Authorization'] = "Bearer #{@client.auth_token}"
    request['Content-Type'] = 'image/png'
    request.body = File.read(file_path)

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    response = http.request(request)

    response.body
  rescue StandardError => e
    Rails.logger.error("Failed to upload rich menu image: #{e.message}")
    nil
  end

  private

  def list_menus(user_id)
    menu_list = @menu_manager.list.join(", ")
    message = "Available menus: #{menu_list}"
    send_message(user_id, message)
  end

  def send_menu(user_id, menu)
    @menu_manager.send_menu(@client, user_id, menu)
  end

  def save_user_state(user_id, menu_id)
    @redis.set("user:#{user_id}:menu", menu_id)
  end

  def get_user_state(user_id)
    @redis.get("user:#{user_id}:menu") || 'main' # Default to the main menu if no state is stored
  end

  def send_message(user_id, text)
    message = { type: 'text', text: }
    @client.push_message(user_id, message)
  end

  def carousel_message(student_id)
    student = Client.find_by(lineid: student_id)
    teachers = student.users

    # default_image = "https://static.line-scdn.net/biz-app/edge/manager/img/cardtypemessage/no_image_600_600.png"
    default_image = 'https://vos.line-scdn.net/card-type-message-image-2024/307rdkih/1724078849413-GwrPKGeKDBIvD9BwXr2YqKo3pQIhyUsndEwqUDtaqjubSwNZxi'
    bubbles = teachers.map do |teacher|
      teacher_bubble(
        name: "#{teacher.first_name} #{teacher.last_name}",
        subject: "English", # Or dynamic if subject is stored in the User model
        image_url: default_image, # Replace with actual image logic
        book_postback_data: "action=book&teacher_id=#{teacher.id}",
        chat_postback_data: "action=chat&teacher_id=#{teacher.id}",
        profile_url: "https://linecorp.com/chat/#{teacher.id}" # Replace with actual chat URL
      )
    end

    {
      type: "flex",
      altText: "Here are some teachers you can choose from.",
      contents: {
        type: "carousel",
        contents: bubbles
      }
    }
  end

  def teacher_bubble(name:, subject:, image_url:, profile_url:, book_postback_data:, chat_postback_data:)
    {
      type: "bubble",
      hero: {
        type: "image",
        url: image_url,
        size: "full",
        aspectRatio: "20:13",
        aspectMode: "cover",
        action: {
          type: "uri",
          label: "Profile",
          uri: profile_url
        }
      },
      body: {
        type: "box",
        layout: "vertical",
        contents: [
          {
            type: "text",
            text: name,
            weight: "bold",
            size: "xl",
            contents: []
          },
          {
            type: "box",
            layout: "vertical",
            spacing: "sm",
            margin: "lg",
            contents: [
              {
                type: "box",
                layout: "baseline",
                contents: [
                  {
                    type: "text",
                    text: "Subject",
                    size: "sm",
                    color: "#AAAAAA",
                    flex: 2,
                    contents: []
                  },
                  {
                    type: "text",
                    text: subject,
                    size: "sm",
                    color: "#666666",
                    flex: 7,
                    wrap: true,
                    contents: []
                  }
                ]
              }
            ]
          }
        ]
      },
      footer: {
        type: "box",
        layout: "vertical",
        flex: 0,
        spacing: "sm",
        contents: [
          {
            type: "button",
            action: {
              type: "postback",
              label: "Availabilities",
              data: book_postback_data,
              displayText: "Booking for #{name}"
            },
            height: "sm",
            style: "link"
          },
          {
            type: "button",
            action: {
              type: "postback",
              label: "Chat",
              data: chat_postback_data,
              displayText: "Chatting with #{name}"
            },
            height: "sm",
            style: "link"
          },
          {
            type: "spacer",
            size: "sm"
          }
        ]
      }
    }
  end

  def your_booking(user_id, event)
    booking_id = extract_booking_id_from_postback(event)
    client = Client.find_by(lineid: user_id)
    booking = client.bookings.find_by(id: booking_id)

    if booking
      booking.destroy
      message = { type: 'text', text: "Your booking has been cancelled successfully." }
    else
      message = { type: 'text', text: "Booking not found or already cancelled." }
    end

    @client.reply_message(event['replyToken'], message)
  end

  def extract_booking_id_from_postback(event)
    postback_data = event['postback']['data']
    Rack::Utils.parse_nested_query(postback_data)['booking_id']
  end

  def show_bookings(user_id, event)
    client = Client.find_by(lineid: user_id)
    bookings = client.bookings.where('start_time > ?', Time.current).order(:start_time).limit(5)

    if bookings.any?
      message = {
        type: 'flex',
        altText: 'Your Bookings',
        contents: {
          type: 'bubble',
          body: {
            type: 'box',
            layout: 'vertical',
            contents: [
              { type: 'text', text: 'Your Bookings', weight: 'bold', size: 'xl' },
              *bookings.map { |booking| booking_box(booking) }
            ]
          }
        }
      }
    else
      message = { type: 'text', text: 'You have no upcoming bookings.' }
    end

    @client.reply_message(event['replyToken'], message)
  end

  def booking_box(booking)
    {
      type: 'box',
      layout: 'horizontal',
      contents: [
        {
          type: 'box',
          layout: 'vertical',
          contents: [
            { type: 'text', text: "#{booking.user.first_name} #{booking.user.last_name}", size: 'sm', weight: 'bold' },
            { type: 'text', text: booking.start_time.strftime("%Y-%m-%d %H:%M"), size: 'xs', color: '#888888' }
          ],
          flex: 4
        },
        {
          type: 'button',
          action: {
            type: 'postback',
            label: 'Cancel',
            data: "action=cancel_booking&id=#{booking.id}"
          },
          style: 'primary',
          color: '#ff3333',
          flex: 1
        }
      ],
      margin: 'md'
    }
  end

  def your_booking(user_id, event)
    booking_id = extract_booking_id_from_postback(event)
    client = Client.find_by(lineid: user_id)
    booking = client.bookings.find_by(id: booking_id)

    if booking
      booking.destroy
      message = { type: 'text', text: "Your booking has been cancelled successfully." }
    else
      message = { type: 'text', text: "Booking not found or already cancelled." }
    end

    @client.reply_message(event['replyToken'], message)
  end
end
