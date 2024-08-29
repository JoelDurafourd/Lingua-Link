require "google/cloud/translate/v2"

module TranslationService
  class Google < TranslationService::Base
    def initialize
      @google_translate = ::Google::Cloud::Translate::V2.new(
        key: ENV.fetch("GOOGLE_TRANSLATE_API_KEY")
      )
    end

    # @param [String] text
    # @param [String] to
    # @param [String | nil] from
    # @return [String]
    def translate(text, to = "ja", from = nil)
      @google_translate.translate(text, to: to, from: from).text
    rescue StandardError => e
      # Log the error and return the original text as a fallback
      Rails.logger.error "Translation failed: #{e.message}"
      text
    end

    # @param [String] text
    # @param [String] to
    # @param [String | nil] from
    # @return [String]
    def t(text, to = "ja", from = nil)
      translate(text, to, from)
    end

    private

    attr_accessor :google_translate
  end
end
