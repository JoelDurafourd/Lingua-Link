require 'json'
require 'time'

module LineService
  class MessageBuilder
    include LineService::Actions

    DEFAULT_THEME = LineService::Theme.new(
      primary_color: "#FFA500", # Orange
      secondary_color: "#FF6347", # Tomato
      accent_color: "#A39696", # Dark Gray
      text_color: "#000000", # Black
      background_color: "#F0EAD6" # Beige
    )

    def initialize(theme: DEFAULT_THEME, translator: TranslationService::Simple.new, locale: :en)
      @theme = theme
      @translator = translator
      @locale = locale
      @base_styles = {
        hero: { backgroundColor: @theme.background_color },
        body: { backgroundColor: @theme.background_color },
        footer: { backgroundColor: @theme.secondary_color }
      }

      @teacher_messages = LineService::Messages::Teachers.new(theme: @theme, base_styles: @base_styles, translator: @translator)
      @student_messages = LineService::Messages::Students.new(theme: @theme, base_styles: @base_styles, translator: @translator)
    end

    def teacher_bubble(name, subject, image_url, teacher_id)
      action_label ||= translate('add_teacher')
      @teacher_messages.bubble(
        name,
        subject,
        image_url,
        action_label,
        LineService::Actions.add_teacher(teacher_id)
      )
    end

    def teacher_interaction_bubble(name, subject, image_url, teacher_id)
      @teacher_messages.interaction_bubble(name, subject, image_url, teacher_id)
    end

    def pagination_bubble(page_id, page_type = "add", extra_params: {})
      LineService::Messages::Core.pagination_bubble(
        page_id,
        page_type,
        @theme,
        @base_styles,
        @translator,
        extra_params: extra_params
      )
    end

    def bookings_bubble(user_name, date, bookings)
      @student_messages.bookings_bubble(user_name, date, bookings)
    end

    def availability_bubble(name, date, time_slots, teacher_id)
      @teacher_messages.availability_bubble(name, date, time_slots, teacher_id)
    end

    def default_rich_menu
      {
        size: {
          width: 2500,
          height: 1686
        },
        selected: true,
        name: "Lingua-Link",
        chatBarText: "Selection Menu",
        areas: [
          {
            bounds: {
              x: 40,
              y: 55,
              width: 788,
              height: 784
            },
            action: {
              type: "postback",
              label: "Find Teachers",  # Add a label for clarity
              text: "Find Teachers",
              data: "action=teachers&action_type=find"
            }
          },
          {
            bounds: {
              x: 845,
              y: 55,
              width: 788,
              height: 784
            },
            action: {
              type: "postback",
              label: "Show Teachers",  # Add a label for clarity
              text: "Show Teachers",
              data: "action=teachers&action_type=show"
            }
          },
          {
            bounds: {
              x: 1665,
              y: 55,
              width: 788,
              height: 784
            },
            action: {
              type: "postback",
              label: "Bookings",  # Add a label for clarity
              text: "Bookings",
              data: "action=teachers&action_type=bookings"
            }
          },
          {
            bounds: {
              x: 853,
              y: 861,
              width: 788,
              height: 784
            },
            action: {
              type: "postback",
              label: "End Chat",  # Add a label for clarity
              text: "End Chat",
              data: "action=chat&action_type=end"
            }
          },
          {
            bounds: {
              x: 1668,
              y: 859,
              width: 788,
              height: 784
            },
            action: {
              type: "postback",
              label: "Translate Settings",  # Add a label for clarity
              text: "Translate Settings",
              data: "action=settings&action_type=translate"
            }
          }
        ]
      }
    end

    private

    def translate(key)
      @translator.translate(key, @locale)
    end

  end
end
