module LineService
  module Actions
    def self.chat_action(label, data, icon_url)
      {
        type: "action",
        imageUrl: icon_url,
        action: {
          type: "postback",
          label:,
          data:
        }
      }
    end

    def self.your_teachers
      "action=teachers&action_type=show"
    end

    def self.find_teachers
      "action=teachers&action_type=find"
    end

    def self.your_bookings
      "action=teachers&action_type=bookings"
    end

    def self.availabilities(teacher_id)
      "action=teachers&action_type=availability&teacher_id=#{teacher_id}"
    end

    def self.start_chat(teacher_id)
      "action=chat&action_type=start&teacher_id=#{teacher_id}"
    end

    def self.end_chat
      "action=chat&action_type=end"
    end

    def self.auto_translation
      "action=settings&action_type=translate"
    end

    def self.add_teacher(teacher_id)
      "action=teachers&action_type=add&teacher_id=#{teacher_id}"
    end

    def self.confirm_booking(availability_id)
      "action=teachers&action_type=confirm_booking&availability_id=#{availability_id}"
    end

    def self.cancel_booking(booking_id)
      "action=student&action_type=cancel_booking&booking_id=#{booking_id}"
    end

    def self.pagination(page_type, next_page, extra_params = {})
      base_query = {
        action: "pagination",
        action_type: page_type,
        page: next_page
      }

      # Merge the base query with any additional parameters
      full_query = base_query.merge(extra_params)

      # Convert the query hash to a URL query string
      full_query.map { |key, value| "#{key}=#{CGI.escape(value.to_s)}" }.join("&")
    end

    def self.book(teacher_id, availability_id)
      "action=teachers&action_type=book&teacher_id=#{teacher_id}&availability_id=#{availability_id}"
    end
  end
end
