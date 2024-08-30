require 'line/bot'
require 'securerandom'
require 'base64'
require 'json'

class LineService
  attr_reader :auth_token, :channel_secret

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

  # Push a message to a specific chat ID
  #
  # @param chat_id [String] The ID of the chat where the message will be sent
  # @param message [Hash] The message content to be sent
  # @return [Hash] A hash containing details about the sent message with the following keys:
  #   - :sent_messages [Array<Hash>] An array containing information about the sent message(s):
  #     - :id [String] The unique identifier for the sent message
  #     - :quote_token [String] A token that can be used to quote or reference the message
  def push_message(chat_id, message)
    raise ArgumentError, "Invalid chat ID provided" unless chat_id.is_a?(String) && chat_id.present?

    # raise ArgumentError, "Message must be a non-empty hash" unless message.is_a?(Hash) && message.present?

    response = handle_response(client.push_message(chat_id, message))

    # Parse the JSON response body and symbolize keys
    response_body = JSON.parse(response.body, symbolize_names: true)

    # Remap the response to follow Ruby conventions
    {
      sent_messages: response_body[:sentMessages].map do |msg|
        {
          id: msg[:id],
          quote_token: msg[:quoteToken]
        }
      end
    }
  end

  def reply_message(reply_token, message)
    Rails.logger.info "Attempting to send reply message for token #{reply_token} with message: #{message.inspect}"

    raise ArgumentError, "Invalid reply token provided" unless reply_token.is_a?(String) && reply_token.present?
    raise ArgumentError, "Message must be a non-empty hash" unless message.is_a?(Hash) && message.present?

    handle_response(client.reply_message(reply_token, message)).tap do
      Rails.logger.info "Reply message sent successfully for token #{reply_token}."
    end
  rescue ArgumentError => e
    Rails.logger.error "ArgumentError in reply_message: #{e.message}"
    raise
  rescue StandardError => e
    Rails.logger.error "Error in reply_message: #{e.class.name} - #{e.message}"
    raise
  end

  # Get the user profile by LINE ID
  #
  # @param user_id [String] Chat ID
  # @return [Hash] A hash containing user profile information with the following keys:
  #   - :user_id [String] The user's LINE ID
  #   - :display_name [String] The user's display name
  #   - :picture_url [String, nil] The URL to the user's profile picture (or nil if not available)
  #   - :language [String, nil] The user's language setting (or nil if not available)
  def get_profile(user_id)
    response = handle_response(client.get_profile(user_id))

    Rails.logger.info "Line user profile retrieved successfully for user ID #{user_id}."

    # Parse the JSON response body
    response_body = JSON.parse(response.body, symbolize_names: true)

    {
      user_id: response_body[:userId],
      display_name: response_body[:displayName],
      picture_url: response_body[:pictureUrl],
      language: response_body[:language]
    }
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

    handle_response(client.post(client.endpoint, endpoint_path, payload, client.credentials))
  end

  # @param [Hash] rich_menu
  # @return [Net::HTTPSuccess]
  def create_rich_menu(rich_menu)
    validation_response = client.validate_rich_menu_object(rich_menu)

    unless validation_response.is_a?(Net::HTTPSuccess)
      Rails.logger.error "Rich menu validation failed: #{validation_response.code} #{validation_response.message}"
      raise "Rich menu validation failed with status #{validation_response.code}"
    end

    response = handle_response(client.create_rich_menu(rich_menu))

    unless response.is_a?(Net::HTTPSuccess)
      Rails.logger.error "Rich menu creation failed: #{validation_response.code} #{validation_response.message}"
      raise "Rich menu creation failed with status #{validation_response.code}"
    end

    response
  end

  def set_default_rich_menu(rich_menu_id)
    client.set_default_rich_menu(rich_menu_id)
  end

  # @param [String] user_id
  # @return [Hash]
  #   - :linkToken [String] The user's account link token
  def create_link_token(user_id)
    raise ArgumentError, "Invalid user ID provided" unless user_id.is_a?(String) && user_id.present?

    response = handle_response(client.create_link_token(user_id))

    # Parse the JSON response body
    response_body = JSON.parse(response.body, symbolize_names: true)

    {
      link_token: response_body[:linkToken]
    }
  end

  # @param [String] link_token
  # @param [String] nonce
  # @return [String]
  def generate_account_link_url(link_token, nonce)
    raise ArgumentError, "Invalid nonce provided" unless nonce.is_a?(String) && nonce.present?

    "https://access.line.me/dialog/bot/accountLink?linkToken=#{ERB::Util.url_encode(link_token)}&nonce=#{ERB::Util.url_encode(nonce)}"
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

  private

  # @param [Net::HTTPResponse] response
  # @return [Object]
  def handle_response(response)
    if response.is_a?(Net::HTTPSuccess)
      Rails.logger.info "Request successful: #{response.message}"
      response
    else
      Rails.logger.error "Request failed: #{response.code} #{response.message} #{response.body}"
      raise "Request failed: #{response.code} #{response.message}"
    end
  end
end
