require 'digest'
require 'base64'

module Utilities
  def self.generate_room_id(client_id, teacher_id)
    combined = "#{client_id}:#{teacher_id}"
    hash = Digest::SHA256.digest(combined)
    Base64.urlsafe_encode64(hash[0...16], padding: false).gsub(/[^a-zA-Z0-9]/, '')
  end

  # def self.parse_postback_data(data)
  #   params = Rack::Utils.parse_nested_query(data)
  #   [params['action'], params['action_type'], params['teacher_id'], params['page'], params['booking_id']]
  # end

  def self.generate_pastel_color
    r = rand(128..255)
    g = rand(128..255)
    b = rand(128..255)
    format("#%<red>02x%<green>02x%<blue>02x", red: r, green: g, blue: b)
  end
end
