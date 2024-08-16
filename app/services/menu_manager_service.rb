require 'redis'
require 'json'

class MenuState
  attr_reader :name

  def initialize(name, menu_manager, user_id)
    @name = name
    @menu_manager = menu_manager
    @user_id = user_id
  end

  def enter
    display_menu
  end

  def handle_input(input)
    raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
  end

  protected

  def display_menu
    menu_items.join("\n")
  end

  def menu_items
    raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
  end

  def transition_to(new_state_name)
    new_state = @menu_manager.transition_to(new_state_name, @user_id)
    new_state.enter
  end
end

class MainMenuState < MenuState
  def initialize(menu_manager, user_id)
    super('main_menu', menu_manager, user_id)
  end

  def handle_input(input)
    case input
    when '#1'
      transition_to('teachers_menu')
    when '#2'
      "Checking your bookings..."
    when '#3'
      "Making a reservation..."
    when '#4'
      "Viewing learning resources..."
    when '#5'
      "Contacting support..."
    else
      "Invalid option. Please try again.\n#{display_menu}"
    end
  end

  protected

  def menu_items
    [
      'Welcome to Lingua Link',
      'Choose an option:',
      ' #1. List Teachers'
      # ' #2. Check Bookings',
      # ' #3. Make a Reservation',
      # ' #4. View Learning Resources',
      # ' #5. Contact Support'
    ]
  end
end

class AvailabilitySelectionMenuState < MenuState
  def initialize(menu_manager, user_id)
    super('availability_selection_menu', menu_manager, user_id)
    @line_service = LineService.new
  end

  def handle_input(input)
    case input
    when /^#(\d+)$/
      number = ::Regexp.last_match(1).to_i
      availabilities = load_availabilities
      if number.positive? && number <= availabilities.length
        selected_availability = availabilities[number - 1]
        book_availability(selected_availability)
      elsif number == availabilities.length + 1
        transition_to('teacher_selected_menu')
      else
        "Invalid option. Please try again.\n#{display_menu}"
      end
    else
      "Invalid option. Please try again.\n#{display_menu}"
    end
  end

  protected

  def menu_items
    teacher = load_teacher
    availabilities = load_availabilities
    [
      "Availabilities for #{teacher.first_name}",
      'Choose an option:',
      *availability_options(availabilities),
      " ##{availabilities.length + 1}. Return to Teacher Menu"
    ]
  end

  private

  def load_teacher
    teacher_id = @menu_manager.session_manager.get(selected_teacher_key)
    User.find(teacher_id)
  end

  def load_availabilities
    teacher_id = @menu_manager.session_manager.get(selected_teacher_key)
    Availability.where(user_id: teacher_id).order(:start_time).to_a
  end

  def selected_teacher_key
    "user:#{@user_id}:selected_teacher"
  end

  def availability_options(availabilities)
    availabilities.map.with_index do |availability, index|
      formatted_date = availability.start_time.strftime("%A, %B %d, %Y")
      formatted_time = "#{availability.start_time.strftime('%I:%M %p')} - #{availability.end_time.strftime('%I:%M %p')}"
      " ##{index + 1}. #{formatted_date}: #{formatted_time}"
    end
  end

  def book_availability(availability)
    success = Availability.transaction do
      avail = Availability.lock.find(availability.id)
      raise ActiveRecord::Rollback, "Availability already booked" if avail.nil?

      client_id = Client.find_by(lineid: @user_id)

      booking = Booking.new(
        user_id: avail.user_id,
        client_id: client_id.id,
        start_time: avail.start_time,
        end_time: avail.end_time
      )

      booking.save!
    end

    # "You've booked a lesson on #{availability.start_time.strftime('%A, %B %d, %Y')} at #{availability.start_time.strftime('%I:%M %p')}.\n\nReturning to teacher menu..."
    if success
      line_message = {
        type: "text",
        text: "You've booked a lesson on #{availability.start_time.strftime('%A, %B %d, %Y')} at #{availability.start_time.strftime('%I:%M %p')}.\n\nReturning to teacher menu...".to_s
      }

      @line_service.push_message(
        @user_id,
        line_message
      )
      transition_to("teacher_selection_menu")
    else
      "Sorry, this availability is no longer available. Please try another.\n\n#{display_menu}"
    end
  end
end

class TeachersMenuState < MenuState
  def initialize(menu_manager, user_id)
    super('teachers_menu', menu_manager, user_id)
  end

  def handle_input(input)
    case input
    when '#1'
      # "Viewing all teachers..."
      transition_to('teacher_selection_menu')
      # when '#2'
      #   "Searching teachers by name..."
      # when '#3'
      #   "Filtering teachers by language or specialty..."
    when '#2'
      transition_to('main_menu')
    else
      "Invalid option. Please try again.\n#{display_menu}"
    end
  end

  protected

  def menu_items
    [
      'List Teachers Menu',
      'Choose an option:',
      ' #1. View All Teachers',
      # ' #2. Search by Name',
      # ' #3. Filter by Language or Specialty',
      ' #2. Return to Main Menu'
    ]
  end
end

class TeacherSelectionMenuState < MenuState
  def initialize(menu_manager, user_id)
    super('teacher_selection_menu', menu_manager, user_id)
    load_teachers
  end

  def handle_input(input)
    case input
    when /^#(\d+)$/
      number = ::Regexp.last_match(1).to_i
      if number == @teachers.length + 1
        transition_to('main_menu')
      elsif number.positive? && number <= @teachers.length
        selected_teacher_id = @menu_manager.session_manager.hget(teacher_map_key, number.to_s)
        set_selected_teacher(selected_teacher_id)
        transition_to('teacher_selected_menu')
      else
        "Invalid option. Please try again.\n#{display_menu}"
      end
    else
      "Invalid option. Please try again.\n#{display_menu}"
    end
  end

  protected

  def menu_items
    if @teachers.empty?
      ["No teachers found."]
    else
      output = ["All Teachers:"]
      @teachers.each_with_index do |teacher, index|
        menu_number = index + 1
        output << " ##{menu_number}. #{teacher.first_name}"
      end
      output << " ##{@teachers.length + 1}. Return to Main Menu"
      output
    end
  end

  private

  def load_teachers
    @teachers = User.all.first(5)
    @teachers.each_with_index do |teacher, index|
      @menu_manager.session_manager.hset(teacher_map_key, (index + 1).to_s, teacher.id)
    end
    @menu_manager.session_manager.expire(teacher_map_key, 3600) # Expire after 1 hour
  end

  def teacher_map_key
    "user:#{@user_id}:teacher_map"
  end

  def selected_teacher_key
    "user:#{@user_id}:selected_teacher"
  end

  def set_selected_teacher(teacher_id)
    @menu_manager.session_manager.set(selected_teacher_key, teacher_id)
    @menu_manager.session_manager.expire(selected_teacher_key, 3600) # Expire after 1 hour
  end
end

class TeacherSelectedMenuState < MenuState
  def initialize(menu_manager, user_id)
    super('teacher_selected_menu', menu_manager, user_id)
    load_teacher
  end

  def handle_input(input)
    case input
    when '#1'
      display_teacher_info
    when '#2'
      transition_to('availability_selection_menu')
    when '#3'
      transition_to('teacher_direct_chat_menu_state')
    when '#4'
      transition_to('main_menu')
    else
      "Invalid option. Please try again.\n#{display_menu}"
    end
  end

  protected

  def menu_items
    [
      "Teacher: #{@teacher.first_name}",
      'Choose an option:',
      ' #1. Display Teacher Info',
      ' #2. Check Availabilities',
      ' #3. Chat w/ teacher',
      ' #4. Return to Main Menu'
    ]
  end

  private

  def load_teacher
    selected_teacher_number = @menu_manager.session_manager.get(selected_teacher_key)
    teacher_id = @menu_manager.session_manager.hget(teacher_map_key, selected_teacher_number)
    @teacher = User.find(teacher_id)
  end

  def teacher_map_key
    "user:#{@user_id}:teacher_map"
  end

  def selected_teacher_key
    "user:#{@user_id}:selected_teacher"
  end

  def display_teacher_info
    "Teacher Information:\nName: #{@teacher.first_name} #{@teacher.last_name}\nEmail: #{@teacher.email}\n"
  end

  def check_teacher_availabilities
    dates_available = Availability.where(user_id: @teacher.id).order(:start_time)

    return "#{@teacher.first_name} has no availabilities at the moment." if dates_available.empty?

    output = ["Availabilities for #{@teacher.first_name}:"]

    dates_available.each_with_index do |availability, index|
      formatted_date = availability.start_time.strftime("%A, %B %d, %Y")
      formatted_time = "#{availability.start_time.strftime('%I:%M %p')} - #{availability.end_time.strftime('%I:%M %p')}"
      output << " ##{index + 1}. #{formatted_date}: #{formatted_time}"
    end

    output << "\nEnter the number of an availability to book, or 'back' to return to the previous menu."
    output.join("\n")
  end
end

class TeacherDirectChatMenuState < MenuState
  def initialize(menu_manager, user_id)
    super('teacher_direct_chat_menu_state', menu_manager, user_id)
    @line_service = LineService.new
  end

  def handle_input(input, event = nil)
    response_object = {
      in_chat: in_chat?,
      content: nil
    }

    if in_chat?
      response_object[:content] = handle_chat_input(input, event)
    else
      case input
      when '#1'
        response_object[:content] = start_chat
      when '#2'
        response_object[:content] = transition_to('teacher_selected_menu')
      else
        response_object[:content] = "Invalid option. Please try again.\n#{display_menu}"
      end
    end

    response_object
  end

  protected

  def menu_items
    teacher = load_teacher
    [
      "Chat with #{teacher.first_name}",
      'Choose an option:',
      ' #1. Open Communication',
      ' #2. Return to Teacher Menu'
    ]
  end

  private

  def load_teacher
    teacher_id = @menu_manager.session_manager.get(selected_teacher_key)
    User.find(teacher_id)
  end

  def selected_teacher_key
    "user:#{@user_id}:selected_teacher"
  end

  def chat_state_key
    "user:#{@user_id}:chat_state"
  end

  def in_chat?
    @menu_manager.session_manager.get(chat_state_key) == 'active'
  end

  def start_chat
    teacher = load_teacher
    @menu_manager.session_manager.set(chat_state_key, 'active')
    @menu_manager.session_manager.expire(chat_state_key, 3600) # Expire after 1 hour
    "You are now in a chat with #{teacher.first_name}. Type your message or '#2' to exit the chat."
  end

  def end_chat
    @menu_manager.session_manager.del(chat_state_key)
  end

  def handle_chat_input(input, event)
    if input == '#2'
      end_chat
      transition_to('teacher_selected_menu')
    else
      teacher = load_teacher

      message_data = event['message']
      source_data = event['source']

      # Extract individual fields
      message_id = message_data['id']
      message_text = message_data['text']
      line_user_id = source_data['userId']
      reply_token = event['replyToken']
      timestamp = event['timestamp']
      client_id = Client.find_by(lineid: line_user_id)&.id

      client_profile = @line_service.get_profile(line_user_id)

      # Log event data (optional)
      # log_event(event)

      translate = Google::Cloud::Translate::V2.new(
        key: ENV.fetch("GOOGLE_TRANSLATE_API_KEY")
      )

      translation = translate.translate(message_text, to: "en")
      translated_message = translation.text

      # Create and store the message in the database
      message = Message.create!(
        message_id:,
        contents: translated_message,
        sender: client_profile[:display_name],
        reply_token:,
        timestamp: Time.at(timestamp / 1000), # Convert timestamp to datetime
        client_id:,
        user_id: teacher.id, # Assuming this is from the client, so user_id can be nil 'TODO: MAKE IT COME FROM LINE WHEN THE USER SELECTS THE ID FROM THE RICH MENU BEFORE RELEASE!'
        uuid: SecureRandom.uuid
      )

      # Broadcast the message to the appropriate ActionCable channel
      ActionCable.server.broadcast(
        "chat_channel",
        {
          message_id: message.uuid,
          is_teacher: false,
          sender: message.sender,
          message: translated_message
        }
      )

      # Here you would implement the logic to send the message to the teacher
      # For now, we'll just echo the message back
      # "Message sent (#{line_user_id}) to #{teacher.first_name}: #{input}\n\nType your next message or '#2' to exit the chat."
    end
  end
end

# class TeacherSelectionMenuState < MenuState
#   def initialize(menu_manager, user_id)
#     super('teacher_selection_menu', menu_manager, user_id)
#     @teachers = User.all.first(5)
#   end
#
#   def handle_input(input)
#     case input
#     when "##{@teachers.length}"
#       "Something here..."
#     when "##{@teachers.length + 1}"
#       transition_to('main_menu')
#     else
#       "Invalid option. Please try again.\n#{display_menu}"
#     end
#   end
#
#   protected
#
#   def menu_items
#     if @teachers.empty?
#       "No teachers found."
#     else
#       output = ["All Teachers:"]
#       @teachers.each_with_index do |teacher, index|
#         output << " ##{index + 1}. #{teacher.first_name}"
#       end
#       output << " ##{@teachers.length + 1}. Return to Main Menu"
#     end
#   end
#
# end

class MenuManagerService
  attr_reader :session_manager

  def initialize
    @session_manager = Redis.new(
      host: '10.0.0.6',
      port: 6379,
      db: 0
    )
  end

  def get_or_create_state(user_id)
    user_state = get_user_state(user_id)
    state_name = user_state['current_state'] || 'main_menu'
    create_state(state_name, user_id)
  end

  def create_state(state_name, user_id)
    case state_name
    when 'main_menu'
      MainMenuState.new(self, user_id)
    when 'teachers_menu'
      TeachersMenuState.new(self, user_id)
    when 'teacher_selection_menu'
      TeacherSelectionMenuState.new(self, user_id)
    when 'teacher_selected_menu'
      TeacherSelectedMenuState.new(self, user_id)
    when 'availability_selection_menu'
      AvailabilitySelectionMenuState.new(self, user_id)
    when 'teacher_direct_chat_menu_state'
      TeacherDirectChatMenuState.new(self, user_id)
    else
      MainMenuState.new(self, user_id) # Fallback to main menu
    end
  end

  def transition_to(new_state_name, user_id)
    set_user_state(user_id, { 'current_state' => new_state_name })
    create_state(new_state_name, user_id)
  end

  def set_user_state(user_id, state)
    @session_manager.set(user_state_key(user_id), state.to_json)
  end

  def get_user_state(user_id)
    state = @session_manager.get(user_state_key(user_id))
    state ? JSON.parse(state) : {}
  end

  def user_state_key(user_id)
    "user:#{user_id}:state"
  end
end
