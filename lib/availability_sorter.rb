# Usage example:
# sorted_bubbles = AvailabilitySorter.sort_bubbles(all_bubbles)
module AvailabilitySorter
  class << self
    def sort_bubbles(bubbles, ascending: true)
      sorted = bubbles.sort_by do |bubble|
        date = extract_date(bubble)
        time_range = extract_time_range(bubble)
        [date, time_range.first]
      end
      ascending ? sorted : sorted.reverse
    end

    private

    def extract_date(bubble)
      date_text = bubble.dig(:body, :contents, 0, :contents, 1, :contents, 1, :text)
      Date.parse(date_text)
    rescue StandardError
      # If parsing fails, return a far future date to push invalid dates to the end
      Date.new(9999, 12, 31)
    end

    def extract_time_range(bubble)
      time_slots = bubble.dig(:body, :contents, 0, :contents, 3, :contents, 0, :contents)
      return [Time.new(9999, 12, 31, 23, 59, 59)] if time_slots.nil? || time_slots.empty?

      first_slot = time_slots.first[:text]
      start_time, = first_slot.split(' - ').map { |t| Time.parse(t) }
      [start_time]
    rescue StandardError
      # If parsing fails, return a far future time to push invalid times to the end
      [Time.new(9999, 12, 31, 23, 59, 59)]
    end
  end
end

