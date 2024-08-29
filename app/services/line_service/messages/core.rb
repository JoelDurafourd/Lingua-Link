module LineService
  module Messages
    module Core

      # @param [String] title
      # @param [LineService::Theme] theme
      def self.header(title, theme)
        {
          type: "box",
          layout: "vertical",
          spacing: "none",
          margin: "none",
          paddingBottom: "10px",
          contents: [
            {
              type: "text",
              text: title,
              weight: "bold",
              size: "xxl",
              align: "center",
              gravity: "center",
              color: theme.text_color,
              contents: []
            },
            {
              type: "separator",
              color: theme.accent_color
            }
          ]
        }
      end

      def self.hero(image_url, aspect_ratio: "1.15:1")
        {
          type: "image",
          url: image_url,
          flex: 1,
          margin: "none",
          align: "center",
          gravity: "center",
          size: "full",
          aspectRatio: aspect_ratio,
          aspectMode: "cover"
        }
      end

      # @param [String] name
      # @param [String] subject
      # @param [LineService::Theme] theme
      # @param [TranslationService::Base] translator
      def self.body(name, subject, theme, translator)
        {
          type: "box",
          layout: "vertical",
          paddingTop: "5px",
          contents: [
            {
              type: "box",
              layout: "vertical",
              paddingTop: "0px",
              contents: [
                {
                  type: "text",
                  text: name,
                  weight: "bold",
                  size: "xl",
                  align: "center",
                  gravity: "center",
                  color: theme.text_color,
                  contents: []
                },
                {
                  type: "box",
                  layout: "baseline",
                  spacing: "xs",
                  paddingStart: "0px",
                  contents: [
                    {
                      type: "text",
                      text: translator.translate('subject'),
                      color: theme.accent_color,
                      flex: 1,
                      contents: []
                    },
                    {
                      type: "text",
                      text: subject,
                      color: theme.text_color,
                      contents: []
                    }
                  ]
                }
              ]
            }
          ]
        }
      end

      # @param [Object] buttons
      # @param [LineService::Theme] theme
      def self.footer(buttons, theme)
        puts "HIT!"
        {
          type: "box",
          layout: "horizontal",
          paddingAll: "0px",
          contents: buttons.map do |button|
            {
              type: "box",
              layout: "vertical",
              backgroundColor: button[:color] || theme.primary_color,
              contents: [self.button(button[:label], button[:data], button[:color] || theme.primary_color)]
            }
          end
        }
      end

      # @param [String] label
      # @param [String] data
      # @param [String] color
      def self.button(label, data, color)
        {
          type: "button",
          action: {
            type: "postback",
            label:,
            data:
          },
          color:,
          margin: "none",
          style: "primary"
        }
      end

      def self.pagination_bubble(page_id, page_type = "add", theme, base_styles, translator, extra_params: {})
        {
          type: "bubble",
          direction: "ltr",
          hero: LineService::Messages::Core.hero("/images/default-group-placeholder.png", aspect_ratio: "1:1"),
          body: {
            type: "box",
            layout: "vertical",
            paddingTop: "5px",
            contents: [
              {
                type: "filler",
                flex: 1
              }
            ]
          },
          footer: LineService::Messages::Core.footer(
            [
              {
                label: translator.translate('view_more'),
                data: LineService::Actions.pagination(page_type, page_id, extra_params)
              }
            ], theme
          ),
          styles: base_styles
        }
      end
    end
  end
end
