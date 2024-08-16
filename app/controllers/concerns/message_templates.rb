# app/services/line_message_templates.rb

class MessageTemplates
  class << self
    def build_teacher_profile(name:, rating:, subject:, experience:, certification:, image_url:, profile_url:)
      MessageBuilder.build_flex_message(
        alt_text: "Teacher Profile: #{name}",
        contents: MessageBuilder.build_bubble(
          hero: build_teacher_hero(image_url, profile_url),
          body: build_teacher_body(name, rating, subject, experience, certification),
          footer: build_teacher_footer(profile_url)
        )
      )
    end

    private

    def build_teacher_hero(image_url, profile_url)
      MessageBuilder.build_hero(
        url: image_url,
        action: MessageBuilder.build_action(
          type: MessageBuilder::ActionType::URI,
          label: "View Full Profile",
          uri: profile_url
        )
      )
    end

    def build_teacher_body(name, rating, subject, experience, certification)
      MessageBuilder.build_body(
        contents: [
          MessageBuilder.build_text(text: name, weight: "bold", size: MessageBuilder::Size::XL),
          build_rating_box(rating),
          build_info_box(subject, experience, certification)
        ]
      )
    end

    def build_rating_box(rating)
      MessageBuilder.build_box(
        layout: MessageBuilder::Layout::BASELINE,
        margin: MessageBuilder::Size::MD,
        contents: build_rating_stars(rating) + [build_rating_text(rating)]
      )
    end

    def build_rating_stars(rating)
      stars = rating.to_i
      (1..5).map do |i|
        MessageBuilder.build_icon(
          url: "https://via.placeholder.com/28x28?text=#{i <= stars ? '★' : '☆'}",
          size: MessageBuilder::Size::SM
        )
      end
    end

    def build_rating_text(rating)
      MessageBuilder.build_text(
        text: rating.to_s,
        size: MessageBuilder::Size::SM,
        color: "#999999",
        flex: 0,
        margin: MessageBuilder::Size::MD
      )
    end

    def build_info_box(subject, experience, certification)
      MessageBuilder.build_box(
        layout: MessageBuilder::Layout::VERTICAL,
        spacing: MessageBuilder::Size::SM,
        margin: MessageBuilder::Size::LG,
        contents: [
          build_info_row("📚", subject),
          build_info_row("🎓", experience),
          build_info_row("🏆", certification)
        ]
      )
    end

    def build_info_row(emoji, text)
      MessageBuilder.build_box(
        layout: MessageBuilder::Layout::BASELINE,
        spacing: MessageBuilder::Size::SM,
        contents: [
          MessageBuilder.build_text(text: emoji, size: MessageBuilder::Size::SM, color: "#AAAAAA", flex: 1),
          MessageBuilder.build_text(text:, size: MessageBuilder::Size::SM, color: "#666666", flex: 5,
                                    wrap: true)
        ]
      )
    end

    def build_teacher_footer(profile_url)
      MessageBuilder.build_footer(
        contents: [
          MessageBuilder.build_spacer,
          MessageBuilder.build_button(
            action: MessageBuilder.build_action(
              type: MessageBuilder::ActionType::DATETIMEPICKER,
              label: "Schedule Class",
              data: "schedule_class",
              mode: "datetime",
              initial: Time.now.strftime("%Y-%m-%dT%H:%M"),
              max: 1.year.from_now.strftime("%Y-%m-%dT%H:%M"),
              min: Time.now.strftime("%Y-%m-%dT%H:%M")
            ),
            color: "#1DB446",
            style: "primary"
          ),
          MessageBuilder.build_button(
            action: MessageBuilder.build_action(
              type: MessageBuilder::ActionType::URI,
              label: "View Full Profile",
              uri: profile_url
            )
          )
        ]
      )
    end
  end
end
