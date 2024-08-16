# app/services/line_message_builder.rb

class MessageBuilder
  # Enums for common values
  module Type
    BUBBLE = 'bubble'.freeze
    BOX = 'box'.freeze
    TEXT = 'text'.freeze
    IMAGE = 'image'.freeze
    ICON = 'icon'.freeze
    BUTTON = 'button'.freeze
    SPACER = 'spacer'.freeze
    FLEX = 'flex'.freeze
  end

  module Layout
    VERTICAL = 'vertical'.freeze
    HORIZONTAL = 'horizontal'.freeze
    BASELINE = 'baseline'.freeze
  end

  module Size
    XXS = 'xxs'.freeze
    XS = 'xs'.freeze
    SM = 'sm'.freeze
    MD = 'md'.freeze
    LG = 'lg'.freeze
    XL = 'xl'.freeze
    XXL = 'xxl'.freeze
    FULL = 'full'.freeze
  end

  module ActionType
    URI = 'uri'.freeze
    MESSAGE = 'message'.freeze
    POSTBACK = 'postback'.freeze
    DATETIMEPICKER = 'datetimepicker'.freeze
  end

  module AspectMode
    COVER = 'cover'.freeze
    FIT = 'fit'.freeze
  end

  # Common aspect ratios
  ASPECT_RATIOS = {
    square: '1:1',
    rectangle: '1.51:1',
    wide: '1.91:1'
  }.freeze

  class << self
    def build_component(type, **options)
      {
        type:,
        **options
      }.compact
    end

    def build_bubble(**options)
      build_component(Type::BUBBLE, **options)
    end

    def build_box(layout:, contents:, **options)
      build_component(Type::BOX, layout:, contents:, **options)
    end

    def build_text(text:, **options)
      build_component(Type::TEXT, text:, **options)
    end

    def build_image(url:, **options)
      build_component(Type::IMAGE, url:, **options)
    end

    def build_icon(url:, **options)
      build_component(Type::ICON, url:, **options)
    end

    def build_button(action:, **options)
      build_component(Type::BUTTON, action:, **options)
    end

    def build_spacer(**options)
      build_component(Type::SPACER, **options)
    end

    def build_action(type:, **options)
      {
        type:,
        **options
      }.compact
    end

    def build_flex_message(alt_text:, contents:)
      {
        type: Type::FLEX,
        altText: alt_text,
        contents:
      }
    end

    # Helper methods for common structures
    def build_hero(url:, **options)
      build_image(
        url:,
        size: options[:size] || Size::FULL,
        aspectRatio: options[:aspect_ratio] || ASPECT_RATIOS[:rectangle],
        aspectMode: options[:aspect_mode] || AspectMode::COVER,
        **options
      )
    end

    def build_body(contents:, **options)
      build_box(layout: Layout::VERTICAL, contents:, **options)
    end

    def build_footer(contents:, **options)
      build_box(layout: Layout::VERTICAL, contents:, spacing: Size::SM, **options)
    end
  end
end
