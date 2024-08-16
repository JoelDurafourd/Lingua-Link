require 'line/bot'
require 'securerandom'
require 'base64'
require 'json'

class LineService
  def initialize(auth_token: nil, channel_secret: nil)
    @auth_token = auth_token || ENV.fetch('LINE_CHANNEL_TOKEN') { raise 'LINE_CHANNEL_TOKEN is not set' }
    @channel_secret = channel_secret || ENV.fetch('LINE_CHANNEL_SECRET') { raise 'LINE_CHANNEL_SECRET is not set' }
  end

  # @return [Line::Bot::Client]
  def client
    @client ||= Line::Bot::Client.new do |config|
      config.channel_secret = @channel_secret
      config.channel_token = @auth_token
    end
  end

  def validate_signature(body, signature)
    client.validate_signature(body, signature)
  end

  def parse_events_from(request_body)
    client.parse_events_from(request_body)
  end

  def push_message(chat_id, message)
    raise ArgumentError, "Invalid chat ID provided" unless chat_id.is_a?(String) && chat_id.present?

    raise ArgumentError, "Message must be a non-empty hash" unless message.is_a?(Hash) && message.present?

    response = client.push_message(chat_id, message)

    if response.is_a?(Net::HTTPSuccess)
      Rails.logger.info "Push message sent successfully to chat ID #{chat_id}."
      response
    else
      Rails.logger.error "Failed to send push message: #{response.code} #{response.message}"
      raise "Failed to send push message"
    end
  end

  def reply_message(reply_token, message)
    Rails.logger.info "Attempting to send reply message for token #{reply_token} with message: #{message.inspect}"

    raise ArgumentError, "Invalid reply token provided" unless reply_token.is_a?(String) && reply_token.present?
    raise ArgumentError, "Message must be a non-empty hash" unless message.is_a?(Hash) && message.present?

    response = client.reply_message(reply_token, message)

    if response.is_a?(Net::HTTPSuccess)
      Rails.logger.info "Reply message sent successfully for token #{reply_token}."
      response
    else
      Rails.logger.error "Failed to send reply message: #{response.code} #{response.message}"
      raise "Failed to send reply message"
    end
  rescue ArgumentError => e
    Rails.logger.error "ArgumentError in reply_message: #{e.message}"
    raise
  rescue StandardError => e
    Rails.logger.error "Error in reply_message: #{e.class.name} - #{e.message}"
    raise
  end

  # Get the user profile by line ID
  #
  # @param chat_id [String] Chat Id
  # @return [Hash]
  def get_profile(user_id)
    response = client.get_profile(user_id)

    if response.is_a?(Net::HTTPSuccess)
      Rails.logger.info "Line user profile started successfully for user id #{user_id}."

      # Parse the JSON response body
      response_body = JSON.parse(response.body)

      {
        user_id: response_body['userId'],
        display_name: response_body['displayName'],
        picture_url: response_body['pictureUrl'],
        language: response_body['language']
      }
    else
      Rails.logger.error "Failed to start Line user profile: #{response.code} #{response.message}"
      raise "Failed to load user profile"
    end
  end

  # Display loading animation to chat using chat id.
  #
  # @param chat_id [String] Chat Id
  # @param loading_seconds [Integer] Display loading animation for 'n' amount of seconds
  # @return [Net::HTTPResponse]
  def loading_animation(chat_id, loading_seconds)
    raise ArgumentError, "Invalid chat_id provided" unless chat_id.is_a?(String) && chat_id.present?

    unless loading_seconds.is_a?(Integer) && loading_seconds.positive?
      raise ArgumentError, "loading_seconds must be a positive integer"
    end

    endpoint_path = '/bot/chat/loading/start'
    payload = { chatId: chat_id, loadingSeconds: loading_seconds }.to_json

    response = client.post(client.endpoint, endpoint_path, payload, client.credentials)

    if response.is_a?(Net::HTTPSuccess)
      Rails.logger.info "Loading animation started successfully for chat #{chat_id}."
      response
    else
      Rails.logger.error "Failed to start loading animation: #{response.code} #{response.message}"
      raise "Failed to start loading animation"
    end
  end

  # @param [Hash] rich_menu
  # @return [Net::HTTPSuccess]
  def create_rich_menu(rich_menu)
    validation_response = client.validate_rich_menu_object(rich_menu)

    unless validation_response.is_a?(Net::HTTPSuccess)
      Rails.logger.error "Rich menu validation failed: #{validation_response.code} #{validation_response.message}"
      raise "Rich menu validation failed with status #{validation_response.code}"
    end

    response = client.create_rich_menu(rich_menu)

    if response.is_a?(Net::HTTPSuccess)
      Rails.logger.info "Rich menu created successfully."
      response
    else
      Rails.logger.error "Failed to create rich menu: #{response.code} #{response.message}"
      raise "Failed to create rich menu"
    end
  end

  def create_link_token(user_id)
    raise ArgumentError, "Invalid user ID provided" unless user_id.is_a?(String) && user_id.present?

    response = client.create_link_token(user_id)

    if response.is_a?(Net::HTTPSuccess)
      Rails.logger.info "Link token created successfully for user ID #{user_id}."
      response
    else
      Rails.logger.error "Failed to create link token for user ID #{user_id}: #{response.code} #{response.message}"
      raise "Failed to create link token"
    end
  end

  def generate_account_link_url(link_token, nonce)
    raise ArgumentError, "Invalid nonce provided" unless nonce.is_a?(String) && nonce.present?

    "https://access.line.me/dialog/bot/accountLink?linkToken=#{ERB::Util.url_encode(link_token)}?nonce=#{ERB::Util.url_encode(nonce)}"
  end

  def generate_nonce_token
    random_bytes = SecureRandom.random_bytes(16)
    nonce = Base64.strict_encode64(random_bytes)

    raise "Nonce length is invalid. Generated nonce length: #{nonce.length}" unless nonce.length.between?(10, 255)

    nonce
  end

  def self.generate_pastel_color
    r = rand(128..255)
    g = rand(128..255)
    b = rand(128..255)
    format("#%<red>02x%<green>02x%<blue>02x", red: r, green: g, blue: b)
  end
end
