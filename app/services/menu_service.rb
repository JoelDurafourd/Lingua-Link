class MenuService
  MENUS = {}

  # Format for Menus
  # "1" => { message: "You selected submenu 1 option 1.", next_menu: "main", logic: :menu_1_logic },
  def initialize
    add('main', 'MENU',
        {
          "1" => "Option 1 Description",
          "2" => "Option 2 Description",
          "3" => "Option 3 Description"
        },
        {
          "1" => { logic: :menu_1_logic },
          "2" => { message: "You selected option 2." },
          "3" => { message: "You selected option 3." }
        })

    add('submenu_1', 'SUBMENU_01',
        {
          "1" => "Submenu 1 Option 1 Description",
          "2" => "Submenu 1 Option 2 Description"
        },
        {
          "1" => { message: "You selected submenu 1 option 1.", next_menu: "main" },
          "2" => { message: "You selected submenu 1 option 2." }
        })

    # Add other menus as needed
  end

  def add(key, keyword, options, responses)
    MENUS[key] = { keyword:, options:, responses: }
  end

  # @param [String] key
  # @return [nil]
  def del(key)
    MENUS.delete(key)
  end

  def get(key)
    MENUS[key]
  end

  def is_exist?(key)
    MENUS.key?(key)
  end

  def list
    MENUS.keys
  end

  def handle_response(client, redis, user_id, menu_key, message_text)
    menu = get(menu_key)
    return send_message(client, user_id, 'Menu not found.') unless menu

    response = menu[:responses][message_text]

    if response
      message_text = execute_logic(response, user_id) || response[:message]
      send_message(client, user_id, message_text)

      if response[:next_menu]
        redis.set("user:#{user_id}:menu", response[:next_menu])
        send_menu(client, user_id, response[:next_menu])
      end
    else
      send_message(client, user_id, 'Invalid option, please try again.')
    end
  end

  def send_menu(client, user_id, menu_key)
    menu = get(menu_key)
    if menu
      message_text = menu[:options].map { |key, value| "#{key}. #{value}" }.join("\n")
      send_message(client, user_id, message_text)
    else
      send_message(client, user_id, 'Menu not found.')
    end
  end

  private

  def execute_logic(response, user_id)
    if response[:logic].is_a?(Symbol)
      send(response[:logic], user_id)
    elsif response[:logic].is_a?(Proc)
      response[:logic].call
    end
  end

  def send_message(client, user_id, text)
    message = { type: 'text', text: }
    client.push_message(user_id, message)
  end

  # Example of a business logic method
  def menu_1_logic(user_id)
    "Business logic for MENU 1 executed for user #{user_id}"
  end
end
