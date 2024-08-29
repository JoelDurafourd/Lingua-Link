module MessageHelper

  # @param [Teacher] teacher
  # @param [Booking] booking
  def accept_booking_message(teacher, booking, line_service: LineService::Client.new)
    student = booking.client

    line_service.push_message(
      student.lineid,
      {
        type: "text",
        text: "Your booked lesson on #{@booking.start_time.strftime('%A, %B %d, %Y')} at #{@booking.start_time.strftime('%I:%M %p')} has been Accepted by  #{teacher.first_name}."
      }
    )
  end

  def decline_booking_message(teacher, booking, line_service: LineService::Client.new)
    student = booking.client

    line_service.push_message(
      student.lineid,
      {
        type: "text",
        text: "Your booked lesson on #{@booking.start_time.strftime('%A, %B %d, %Y')} at #{@booking.start_time.strftime('%I:%M %p')} has been Declined by  #{teacher.first_name}."
      }
    )
  end

end
