module LineService
  module Messages
    class Students
      def initialize(theme:, base_styles:, translator:)
        @theme = theme
        @base_styles = base_styles
        @translator = translator
      end

      def booking_bubble(user_name, date, bookings)
        {
          type: "bubble",
          direction: "ltr",
          body: {
            type: "box",
            layout: "vertical",
            paddingTop: "15px",
            contents: [
              {
                type: "text",
                text: "#{user_name}'s Bookings",
                weight: "bold",
                size: "xl",
                align: "center",
                gravity: "center",
                color: @theme.text_color,
                contents: []
              },
              {
                type: "separator",
                margin: "md",
                color: @theme.accent_color
              },
              {
                type: "text",
                text: date.strftime('%B %d, %Y'),
                weight: "bold",
                color: @theme.accent_color,
                wrap: true,
                contents: []
              },
              {
                type: "box",
                layout: "vertical",
                spacing: "sm",
                paddingTop: "10px",
                contents: bookings.map { |booking| booking_details(booking) }
              }
            ]
          },
          styles: @base_styles
        }
      end

      def booking_details(booking)
        start_time = booking.start_time.strftime('%I:%M %p')
        end_time = booking.end_time.strftime('%I:%M %p')

        {
          type: "box",
          layout: "horizontal", # Ensure this is horizontal for proper alignment
          contents: [
            {
              type: "text",
              text: "#{start_time} - #{end_time}",
              size: "sm",
              color: @theme.text_color,
              flex: 2,
              wrap: true
            },
            {
              type: "button",
              action: {
                type: "postback",
                label: "Cancel",
                data: "action=cancel_booking&booking_id=#{booking.id}"
              },
              height: "sm",
              style: "primary",
              flex: 1
            }
          ]
        }
      end

      def bookings_bubble(name, date, time_slots)
        {
          type: "bubble",
          direction: "ltr",
          body: bookings_body(name, date, time_slots),
          footer: LineService::Messages::Core.footer(
            [
              {
                label: @translator.translate('times_subject_to_change'),
                data: "action=none"
              }],
            @theme
          ),
          styles: @base_styles
        }
      end

      def bookings_body(name, date, time_slots)
        {
          type: "box",
          layout: "vertical",
          paddingTop: "15px",
          contents: [
            {
              type: "box",
              layout: "vertical",
              paddingTop: "0px",
              contents: [
                {
                  type: "text",
                  text: "#{name} #{@translator.translate("bookings")}",
                  weight: "bold",
                  size: "xl",
                  align: "center",
                  gravity: "center",
                  color: @theme.text_color,
                  contents: []
                },
                {
                  type: "box",
                  layout: "baseline",
                  spacing: "xs",
                  paddingBottom: "10px",
                  paddingStart: "0px",
                  contents: [
                    {
                      type: "text",
                      text: "Date",
                      color: @theme.accent_color,
                      flex: 0,
                      contents: []
                    },
                    {
                      type: "text",
                      text: date,
                      color: @theme.text_color,
                      flex: 1,
                      align: "end",
                      wrap: true,
                      contents: []
                    }
                  ]
                },
                {
                  type: "separator",
                  color: @theme.accent_color
                },
                {
                  type: "box",
                  layout: "vertical",
                  spacing: "sm",
                  paddingTop: "10px",
                  contents: time_slots.map { |slot| time_slot(date, slot) }
                }
              ]
            }
          ]
        }
      end

      def time_slot(date, slot)
        {
          type: "box",
          layout: "horizontal",
          contents: [
            {
              type: "text",
              text: slot[:time_range],
              weight: "bold",
              flex: 2,
              align: "start",
              gravity: "center",
              color: @theme.text_color,
              size: "sm",
              contents: []
            },
            LineService::Messages::Core.button(
              @translator.translate('cancel'),
              # LineService::Actions.book(teacher_id, slot[:availability_id]),
              LineService::Actions.cancel_booking(slot[:booking_id]),
              @theme.primary_color
            )
          ]
        }
      end

    end
  end
end
