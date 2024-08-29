class AvailabilityBubbleCreator
  def self.create_bubbles(availabilities, teacher, message_builder)
    availabilities_by_date = group_availabilities(availabilities)

    availabilities_by_date.map do |date, availabilities_for_date|
      create_bubble_for_date(date, availabilities_for_date, teacher, message_builder)
    end
  end

  class << self
    private

    def group_availabilities(availabilities)
      availabilities.group_by { |availability| availability.start_time.to_date }
    end

    def create_bubble_for_date(date, availabilities_for_date, teacher, message_builder)
      time_slots = availabilities_for_date.map { |availability| format_time_slot(availability) }

      message_builder.availability_bubble(
        "#{teacher.first_name} #{teacher.last_name}",
        date.strftime('%B %d, %Y'),
        time_slots,
        teacher.id
      )
    end

    def format_time_slot(availability)
      {
        time_range: format_time_range(availability),
        availability_id: availability.id
      }
    end

    def format_time_range(availability)
      "#{availability.start_time.strftime('%I:%M %p')} - #{availability.end_time.strftime('%I:%M %p')}"
    end
  end
end