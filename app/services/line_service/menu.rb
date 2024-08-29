module LineService
  class Menu
    include ::ActionCableHelper

    attr_accessor :client, :online_translation, :redis, :menu_manager

    def initialize(
      client,
      online_translation: ::TranslationService::Google.new,
      redis: ::DatabaseService::RedisClient.new
    )
      @client = client
      @online_translation = online_translation
      @redis = redis

      @message_builder = LineService::MessageBuilder.new(translator: ::TranslationService::Simple.new, locale: :en)
    end

    def handle_events(events)
      Rails.logger.info "Processing #{events.size} LINE events"

      # Get UserID
      # Get UserProfile
      # Check if UserProfile has changes
      # Update if UserProfile has changes

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

    # @param [Line::Bot::Event::Message] event
    def handle_message(event)
      message_event = parse_message_event(event)

      line_id = message_event[:line_id]
      message_id = message_event[:message_id]
      message_text = message_event[:message_text]
      reply_token = message_event[:reply_token]
      timestamp = message_event[:timestamp]

      user_profile = @client.get_profile(line_id)
      user_language = user_profile[:language].to_s

      # Testing Debug Creation of RichMenu!
      if message_text == "DEBUG--BUILD-RICH-MENU"
        build_and_set_rich_menu
        message = {
          type: 'text',
          text: "Debug -- RichMenu has been created!"
        }
        return reply_message(event['replyToken'], message)
      end

      client = ::Client.find_by(lineid: line_id)
      client_id = client.id
      client_chat_id = client.user_chat_id

      message_text = @online_translation.translate(message_text, 'en')

      # Create Message Object
      message = ::Message.create!(
        message_id:,
        contents: message_text,
        sender: user_profile[:display_name],
        reply_token:,
        timestamp: Time.at(timestamp / 1000), # Convert timestamp to datetime
        client_id:,
        user_id: client_chat_id,
        uuid: SecureRandom.uuid
      )

      broadcast_to_chat_room(
        message.client_id,
        message.user_id,
        message.uuid,
        message.sender,
        message.contents,
        is_teacher: false
      )
    end

    # @param [Line::Bot::Event::Postback] event
    def handle_postback(event)
      user_id = event['source']['userId']
      data = event['postback']['data']
      action, action_type, teacher_id, page, availability_id, booking_id = parse_postback_data(data)

      case action
      when 'teachers'
        case action_type
        when 'add' # Add A Teacher
          add_teacher_to_user(user_id, teacher_id, event)
        when 'availability'
          handle_availabilities(teacher_id, user_id, event)
        when 'show' # Show Your Teachers
          show_your_teachers(user_id, event)
        when 'find' # Find New Teachers
          find_teachers(user_id, event)
        when 'book' # Book A Teacher
          handle_booking(teacher_id, user_id, availability_id, event)
        when 'bookings'
          handle_show_bookings(user_id, event)
        else
          Rails.logger.error "Unknown postback action: #{action}, action_type #{action_type}"
        end
      when "student"
        case action_type
        when "cancel_booking"
          handle_cancel_booking(user_id, booking_id, event)
        else
          Rails.logger.error "Unknown postback action: #{action}, action_type #{action_type}"
        end
      when 'pagination'
        case action_type
        when "add" # Add A Teacher Pagination
          find_teachers(user_id, event, page: page.to_i)
        when "show" # Show Your Teachers Pagination
          show_your_teachers(user_id, event, page: page.to_i)
        when "availability"
          handle_availabilities(teacher_id, user_id, event, page: page.to_i)
        when "bookings"
          handle_show_bookings(user_id, event, page: page.to_i)
        else
          Rails.logger.error "Unknown postback action: #{action}, action_type #{action_type}"
        end
      when "chat"
        case action_type
        when "start"
          handle_chat(user_id, teacher_id, event)
        when "end"
          handle_chat_session_end(user_id, event)
        else
          Rails.logger.error "Unknown postback action: #{action}, action_type #{action_type}"
        end
      when 'settings'
        case action_type
        when 'translate'
          enable_auto_translation(user_id, event)
        else
          Rails.logger.error "Unknown postback action: #{action}, action_type #{action_type}"
        end
      else
        Rails.logger.error "Unknown postback action: #{action}"
      end
    end

    def handle_cancel_booking(user_id, booking_id, event)
      client = ::Client.find_by(lineid: user_id)

      if client.nil?
        Rails.logger.error "Client not found with LINE ID #{user_id}"
        return
      end
      booking = client.bookings.find_by(id: booking_id)

      if booking.nil?
        Rails.logger.error "Booking not found with BOOKING ID #{booking_id}"
        return
      end

      return unless booking.update(status: :canceled)

      confirmation_message = {
        type: "text",
        text: "Your booking for #{booking.start_time.strftime('%B %d, %Y - %I:%M %p')} has been canceled."
      }

      reply_message(event['replyToken'], confirmation_message)

    end

    def handle_show_bookings(user_id, event, page: 1)
      client = ::Client.find_by(lineid: user_id)
      unless client
        Rails.logger.error "Client not found with LINE ID #{user_id}"
        return
      end

      current_time = Time.current
      bookings = ::Booking
                   .where(client_id: client.id, status: [:pending, :accepted])
                   .where('start_time > ?', current_time)
                   .order(:start_time)

      if bookings.any?
        bookings_by_date = bookings.group_by { |booking| booking.start_time.to_date }
        Rails.logger.debug "Grouped and sorted bookings by date: #{bookings_by_date.inspect}"

        all_bubbles = bookings_by_date.flat_map do |date, slots_for_date|
          time_slots = slots_for_date.map do |booking|
            {
              time_range: "#{booking.start_time.strftime('%I:%M %p')} - #{booking.end_time.strftime('%I:%M %p')}",
              booking_id: booking.id
            }
          end
          Rails.logger.debug "Formatted time slots for date #{date}: #{time_slots.inspect}"
          @message_builder.bookings_bubble(client.name, date.strftime('%B %d, %Y'), time_slots)
        end

        per_page = 5
        total_pages = (all_bubbles.size.to_f / per_page).ceil
        page = [[page, 1].max, total_pages].min
        offset = (page - 1) * per_page

        paginated_bubbles = all_bubbles[offset, per_page] || []

        if paginated_bubbles.any?
          if page < total_pages
            paginated_bubbles << @message_builder.pagination_bubble(page + 1, "bookings")
          end

          message = {
            type: "flex",
            altText: "Here are your upcoming bookings.",
            contents: {
              type: "carousel",
              contents: paginated_bubbles
            }
          }
        else
          message = { type: "text", text: "There are no upcoming bookings at the moment." }
        end
      else
        message = { type: "text", text: "There are no upcoming bookings at the moment." }
      end

      reply_message(event['replyToken'], message, is_chatting: client.user_chat_id)
    end

    #     # Create the carousel message with all the booking bubbles
    #     message = {
    #       type: "flex",
    #       altText: "Here are your current bookings.",
    #       contents: {
    #         type: "carousel",
    #         contents: all_bubbles
    #       }
    #     }
    #
    #     # Display the carousel of bookings
    #     reply_message(event['replyToken'], message)
    #   else
    #     # If no bookings are available
    #     message = @message_builder.text_message(
    #       "You currently have no bookings."
    #     )
    #     reply_message(event['replyToken'], message)
    #   end
    # end

    # @param [Line::Bot::Event::Follow] event
    def handle_follow(event)
      user_id = event['source']['userId']

      # Fetch user profile from LINE
      user_profile = @client.get_profile(user_id)
      display_name = user_profile[:display_name]
      user_language = user_profile[:language]

      # Check if the client already exists
      client = ::Client.find_or_initialize_by(lineid: user_id)

      if client.new_record?
        client.name = display_name
        client.phone_number = "" # Assuming phone_number is optional or blank by default
        client.language = user_language
        client.save!
        Rails.logger.info "New client created: #{client.inspect}"
      else
        Rails.logger.info "Existing client found: #{client.inspect}"
      end

      # Prepare and send the welcome message
      message = {
        type: "text",
        text: "Welcome! You can start using Lingua-Link on your smartphone by selecting one of the menu options."
      }

      begin
        response = reply_message(event['replyToken'], message, is_chatting: client.user_chat_id)
        Rails.logger.info "Welcome message sent successfully to user #{user_id} with response #{response}"
      rescue StandardError => e
        Rails.logger.error "Error sending welcome message to user #{user_id}: #{e.message}"
      end
    end

    # @param [Line::Bot::Event::Unfollow] event
    def handle_unfollow(event)
      user_id = event['source']['userId']
      student = ::Client.find_by(lineid: user_id)

      if student
        # Destroy associated messages
        ::Message.where(client_id: student.id).destroy_all
        ::Booking.where(client_id: student.id).delete_all

        # Destroy associations with users (teachers)
        student.users.clear

        # Destroy the client record (student)
        student.destroy

        Rails.logger.info "Destroyed client #{user_id} and all associated data."
      else
        Rails.logger.warn "Client with lineid #{user_id} not found."
      end
    end

    #### Teachers Start
    def add_teacher_to_user(user_id, teacher_id, event)
      teacher = ::User.find_by(id: teacher_id)
      student = ::Client.find_by(lineid: user_id)

      if student.users << teacher
        Rails.logger.info "User #{user_id} added teacher #{teacher_id}."
        message = {
          type: "text",
          text: "You have connected with teacher #{teacher.first_name}."
        }
      else
        Rails.logger.error "Teacher not found with ID #{teacher_id}."
        message = {
          type: "text",
          text: "There was an issue adding the teacher."
        }
      end
      reply_message(event['replyToken'], message)
    end

    def show_your_teachers(user_id, event, page: 1)
      Rails.logger.info "Displaying teachers for user #{user_id}."
      student = ::Client.find_by(lineid: user_id)

      if student&.users&.exists?
        per_page = 5
        total_teachers = student.users.count
        total_pages = (total_teachers.to_f / per_page).ceil

        # Ensure page is within bounds
        page = [[page, 1].max, total_pages].min
        offset = (page - 1) * per_page

        teachers = student.users.offset(offset).limit(per_page)

        bubbles = teachers.map do |teacher|
          image_url = teacher.photo.url.presence || "https://static.vecteezy.com/system/resources/thumbnails/003/337/634/small/profile-placeholder-default-avatar-vector.jpg"
          @message_builder.teacher_interaction_bubble(
            "#{teacher.first_name} #{teacher.last_name}",
            "English",
            image_url,
            teacher.id
          )
        end

        # Add pagination bubble if there's a next page
        bubbles << @message_builder.pagination_bubble(page + 1, "show") if page < total_pages

        message = {
          type: "flex",
          altText: "Here are your teachers you can interact with.",
          contents: {
            type: "carousel",
            contents: bubbles
          }
        }

        reply_message(event['replyToken'], message, is_chatting: student.user_chat_id)
      else
        no_teachers_message = {
          type: 'text',
          text: 'You currently have no teachers associated with your account.'
        }
        reply_message(event['replyToken'], no_teachers_message)
      end
    end

    def find_teachers(user_id, event, page: 1)
      Rails.logger.info "Finding teachers for user #{user_id} on page #{page}."
      student = ::Client.find_by(lineid: user_id)

      if student
        per_page = 5
        excluded_teacher_ids = student.users.pluck(:id)

        # Get total count of available teachers
        total_teachers = ::User.where.not(id: excluded_teacher_ids).count
        total_pages = (total_teachers.to_f / per_page).ceil

        # Ensure page is within bounds
        page = [[page, 1].max, total_pages].min
        offset = (page - 1) * per_page

        teachers = ::User.where.not(id: excluded_teacher_ids)
                         .offset(offset)
                         .limit(per_page)

        if teachers.any?
          bubbles = teachers.map do |teacher|
            image_url = teacher.photo.url.presence || "#{ENV.fetch('APP_BASE_URL')}/images/default-neutral-placeholder.png"
            @message_builder.teacher_bubble(
              "#{teacher.first_name} #{teacher.last_name}",
              "English",
              image_url,
              teacher.id
            )
          end

          # Add pagination bubble if there's a next page
          bubbles << @message_builder.pagination_bubble(page + 1, "add") if page < total_pages

          # Create the carousel message
          message = {
            type: "flex",
            altText: "Here are some teachers you can add.",
            contents: {
              type: "carousel",
              contents: bubbles
            }
          }
        else
          # No teachers available
          Rails.logger.info "No additional teachers found for user #{user_id}."
          message = {
            type: "text",
            text: "There are no more teachers available at the moment."
          }
        end
      else
        # Student not found
        Rails.logger.error "Student not found with lineid #{user_id}."
        message = {
          type: "text",
          text: "We couldn't find your account. Please try again later."
        }
      end

      # Send the message to the user
      response = reply_message(event['replyToken'], message, is_chatting: student&.user_chat_id)
      Rails.logger.info "Sent message for user #{user_id} on page #{page} with response #{response}."
    end

    def handle_booking(teacher_id, user_id, availability_id, event)
      client = ::Client.find_by(lineid: user_id)
      teacher = ::User.find_by(id: teacher_id.to_i)
      availability = ::Availability.find_by(id: availability_id)

      if client.present? && availability.present? && teacher.present?

        booking = ::Booking.new(
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

          reply_message(event['replyToken'], confirmation_message, is_chatting: client.user_chat_id)
        else
          Rails.logger.error "Booking not found"
        end

      else
        Rails.logger.error "Availability not found with ID #{availability_id}"
      end

    end

    def handle_availabilities(teacher_id, user_id, event, page: 1)
      teacher = ::User.find_by(id: teacher_id)
      client = ::Client.find_by(lineid: user_id)

      if teacher && client
        Rails.logger.info "Booking request received for teacher #{teacher.id} - #{teacher.first_name} #{teacher.last_name}"

        per_page = 5
        start_date = Date.today.beginning_of_day
        end_date = start_date + 30.days
        availabilities_by_day = teacher.availabilities
                                       .select("availabilities.*, DATE(start_time) AS date")
                                       .where(start_time: start_date..end_date.end_of_day)
                                       .order(:start_time)
                                       .group_by { |a| a.date.to_date }

        sorted_dates = availabilities_by_day.keys.sort
        total_pages = (sorted_dates.size.to_f / per_page).ceil
        offset = (page - 1) * per_page

        # Paginate the dates
        paginated_dates = sorted_dates[offset, per_page]

        if paginated_dates.present?
          # Retrieve availabilities for the current page's dates in order
          paginated_availabilities = paginated_dates.map { |date| availabilities_by_day[date] }.flatten

          # Create bubbles for the current page of dates
          bubbles = ::AvailabilityBubbleCreator.create_bubbles(
            paginated_availabilities,
            teacher,
            @message_builder
          )
          Rails.logger.debug "Created bubbles: #{bubbles.count}"

          # Check if there's a next page
          has_next_page = page < total_pages

          if has_next_page
            bubbles << @message_builder.pagination_bubble(page + 1, "availability", extra_params: { teacher_id: teacher_id })
          end

          Rails.logger.debug "Total bubbles (including pagination): #{bubbles.count}"

          message = {
            type: "flex",
            altText: "Here are your available booking slots.",
            contents: {
              type: "carousel",
              contents: bubbles
            }
          }
        else
          message = { type: "text", text: "There are no available booking slots for this teacher at the moment." }
        end

        reply_message(event['replyToken'], message)
      else
        Rails.logger.error "Teacher not found with ID #{teacher_id} or Client not found with lineid #{user_id}"
      end
    end

    #### Teachers End

    #### Chat Start
    def handle_chat(user_id, teacher_id, event)
      client = ::Client.find_by(lineid: user_id)
      teacher = ::User.find_by(id: teacher_id)

      if client && teacher
        # Assign the current teacher to the client for chatting
        client.update(user_chat_id: teacher_id)
        Rails.logger.info "Chat initiated between client #{client.id} and teacher #{teacher.id}"

        # Respond to the user confirming the chat initiation
        message = {
          type: 'text',
          text: "You are now chatting with #{teacher.first_name} #{teacher.last_name}. How can they assist you today?"
        }
      else
        Rails.logger.error "Chat initiation failed: Client or Teacher not found."
        message = {
          type: 'text',
          text: "Unable to initiate chat. Please try again later."
        }
      end
      reply_message(event['replyToken'], message, is_chatting: client.user_chat_id)
    end

    def assign_chat_to_client(client, user_chat_id)
      client.update(user_chat_id: user_chat_id)
      Rails.logger.info "Assigned user_chat_id #{user_chat_id} to client #{client.id}"
    end

    def handle_chat_session_end(user_id, event)
      client = ::Client.find_by(lineid: user_id)

      if client
        if client.user_chat_id.nil?
          Rails.logger.info "No active chat session for client #{client.id}"
          message = { type: 'text', text: "No active chat session to end." }
        else
          client.update(user_chat_id: nil)
          Rails.logger.info "Ended chat session for client #{client.id}"
          message = { type: 'text', text: "Chat session ended successfully." }
        end
        reply_message(event['replyToken'], message, is_chatting: client.user_chat_id)
      else
        Rails.logger.warn "Client with LINE ID #{user_id} not found"
        message = { type: 'text', text: "Client not found." }
        reply_message(event['replyToken'], message)
      end
    end

    #### Chat End

    #### Settings Start
    def enable_auto_translation(user_id, event)
      Rails.logger.info "Enabling auto translation for user #{user_id}."

      student = ::Client.find_by(lineid: user_id)

      if student.nil?
        message = {
          type: 'text',
          text: "User not found."
        }
        reply_message(event['replyToken'], message)
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

      reply_message(event['replyToken'], message, is_chatting: student.user_chat_id)
    end

    #### Settings End

    #### RICH MENU -- (MOVE MAYBE)
    def create_rich_menu
      menu_01 = @message_builder.default_rich_menu

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
      uri = ::URI.parse(url)

      request = ::Net::HTTP::Post.new(uri)
      request['Authorization'] = "Bearer #{@client.auth_token}"
      request['Content-Type'] = 'image/png'
      request.body = ::File.read(file_path)

      http = ::Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      response = http.request(request)

      response.body
    rescue StandardError => e
      Rails.logger.error("Failed to upload rich menu image: #{e.message}")
      nil
    end

    #### RICH MENU -- (MOVE MAYBE)

    private

    # @param [Line::Bot::Event::Message] event
    def parse_message_event(event)
      source_data = event['source']
      message_data = event['message']

      {
        line_id: source_data['userId'],
        timestamp: event['timestamp'],
        message_id: message_data['id'],
        message_text: message_data['text'],
        reply_token: event['replyToken']
      }
    end

    # @param [Line::Bot::Event::Postback] event
    def extract_availability_id_from_postback(event)
      postback_data = event['postback']['data']
      Rack::Utils.parse_nested_query(postback_data)['availability_id']
    end

    def parse_postback_data(data)
      params = Rack::Utils.parse_nested_query(data)
      [params['action'], params['action_type'], params['teacher_id'], params['page'], params['availability_id'], params['booking_id']]
    end

    # def save_user_state(user_id, menu_id)
    #   @redis.set("user:#{user_id}:menu", menu_id)
    # end
    #
    # def get_user_state(user_id)
    #   @redis.get("user:#{user_id}:menu") || 'main' # Default to the main menu if no state is stored
    # end

    def send_message(user_id, message, is_chatting: nil)
      quick_reply_menu = quick_actions(is_chatting)
      message.merge!(quick_reply_menu)

      @client.push_message(user_id, message)
    end

    def reply_message(reply_token, message, is_chatting: nil)
      quick_reply_menu = quick_actions(is_chatting)
      message.merge!(quick_reply_menu)

      @client.reply_message(reply_token, message)
    end

    def quick_actions(is_chatting)
      # Initialize the quickReply structure
      default_reply = {
        quickReply: {
          items: []
        }
      }

      # Conditional logic to append different actions based on is_chatting
      if is_chatting.present? && !is_chatting.nil?
        default_reply[:quickReply][:items] << {
          type: "action",
          imageUrl: "https://www.svgrepo.com/show/1113/inkwell.svg",
          action: {
            type: "postback",
            label: "End Chat",
            data: LineService::Actions.end_chat
          }
        }
      else
        default_reply[:quickReply][:items].push(

          {
            type: "action",
            imageUrl: "https://www.svgrepo.com/show/148898/teacher-desk.svg",
            action: {
              type: "postback",
              label: "Your Teachers",
              data: LineService::Actions.your_teachers
            }
          },
          {
            type: "action",
            imageUrl: "https://www.svgrepo.com/show/22234/mortarboard.svg",
            action: {
              type: "postback",
              label: "Find Teachers",
              data: LineService::Actions.find_teachers
            }
          },
          {
            type: "action",
            action: {
              type: "postback",
              label: "Your Bookings",
              data: LineService::Actions.your_bookings
            }
          }

        )
      end

      # Always append the translation action at the end
      default_reply[:quickReply][:items] << {
        type: "action",
        imageUrl: "https://www.svgrepo.com/show/3731/pen.svg",
        action: {
          type: "postback",
          label: "Translation",
          data: LineService::Actions.auto_translation
        }
      }

      default_reply
    end
  end
end
