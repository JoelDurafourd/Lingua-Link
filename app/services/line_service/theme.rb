module LineService
  class Theme
    attr_reader :primary_color, :secondary_color, :accent_color, :text_color, :background_color

    def initialize(primary_color:, secondary_color:, accent_color:, text_color:, background_color:)
      @primary_color = primary_color
      @secondary_color = secondary_color
      @accent_color = accent_color
      @text_color = text_color
      @background_color = background_color
    end

    def to_h
      {
        primary_color: @primary_color,
        secondary_color: @secondary_color,
        accent_color: @accent_color,
        text_color: @text_color,
        background_color: @background_color
      }
    end
  end
end
