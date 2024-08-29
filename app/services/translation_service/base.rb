module TranslationService
  class Base
    def initialize
      raise NotImplementedError, "Subclasses must implement an initialize method"
    end

    # @param [String] text
    # @param [String] to
    # @param [String | nil] from
    # @return [String]
    def translate(text, to = "ja", from = nil)
      raise NotImplementedError, "Subclasses must implement a translate method"
    end

    # @param [String] text
    # @param [String] to
    # @param [String | nil] from
    # @return [String]
    def t(text, to = "ja", from = nil)
      raise NotImplementedError, "Subclasses must implement a t method"
    end
  end
end
