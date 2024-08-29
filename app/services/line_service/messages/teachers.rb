module LineService
  module Messages
    class Teachers

      def initialize(theme:, base_styles:, translator:)
        @theme = theme
        @base_styles = base_styles
        @translator = translator
      end

      def bubble(
        name,
        subject,
        image_url,
        action_label = nil,
        action_data = LineService::Actions.add_teacher("-1")
      )
        action_label ||= @translator.translate('add_teacher')
        {
          type: "bubble",
          direction: "ltr",
          hero: LineService::Messages::Core.hero(image_url),
          body: LineService::Messages::Core.body(name, subject, @theme, @translator),
          footer: LineService::Messages::Core.footer([{ label: action_label, data: action_data }], @theme),
          styles: @base_styles
        }
      end

      # @param [String] name
      # @param [String] subject
      # @param [String] image_url
      # @param [Integer] teacher_id
      def interaction_bubble(name, subject, image_url, teacher_id)
        {
          type: "bubble",
          direction: "ltr",
          hero: LineService::Messages::Core.hero(image_url),
          body: LineService::Messages::Core.body(name, subject, @theme, @translator),
          footer: LineService::Messages::Core.footer(
            [
              {
                label: @translator.translate('availabilities'),
                data: LineService::Actions.availabilities(teacher_id),
                color: @theme.secondary_color
              },
              { label: @translator.translate('chat'), data: LineService::Actions.start_chat(teacher_id) }
            ],
            @theme
          ),
          styles: @base_styles
        }
      end

      def availability_bubble(name, date, time_slots, teacher_id)
        {
          type: "bubble",
          direction: "ltr",
          body: availability_body(name, date, time_slots, teacher_id),
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



      def availability_body(name, date, time_slots, teacher_id)
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
                  text: name,
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
                  contents: time_slots.map { |slot| time_slot(date, slot, teacher_id) }
                }
              ]
            }
          ]
        }
      end

      def time_slot(date, slot, teacher_id)
        {
          type: "box",
          layout: "horizontal",
          contents: [
            {
              type: "text",
              text: date,
              weight: "bold",
              flex: 2,
              align: "start",
              gravity: "center",
              color: @theme.text_color,
              size: "sm",
              contents: []
            },
            LineService::Messages::Core.button(
              @translator.translate('book'),
              LineService::Actions.book(teacher_id, slot[:availability_id]),
              # "action=book&time=#{format_time_range_epoch(date, time_range)}",
              @theme.primary_color
            )
          ]
        }
      end

      def format_time_range_epoch(date, time_range)
        start_time_str, end_time_str = time_range.split(' - ')

        # Parse the full date and time
        start_time = Time.parse("#{date} #{start_time_str}")
        end_time = Time.parse("#{date} #{end_time_str}")

        # Convert to epoch (Unix timestamp)
        start_epoch = start_time.to_i
        end_epoch = end_time.to_i

        "#{start_epoch}/#{end_epoch}"
      end

      # @param [Array<User>] teachers
      # @param [Integer | nil] next_page
      def carousel(teachers, next_page = nil)
        bubbles = teachers.map do |teacher|
          interaction_bubble(
            teacher.name,
            teacher.language,
            teacher.photo.url || "/images/default-female-placeholder.png",
            teacher.id
          )
        end
        bubbles << create_pagination_bubble(next_page) if next_page

        { type: "carousel", contents: bubbles }
      end
    end
  end
end
