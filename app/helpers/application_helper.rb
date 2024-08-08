module ApplicationHelper
  def month_offset(date)
    # sets the amount of days since the start of the month to remove from the calendar so they appear on the correct day.
    (date.beginning_of_month.wday - 1) % 7
  end

  def day_num_ender(day_number)
    # adds an ender to days of the month depending on what day it is
    last_number = day_number.to_s.chars.last
    if last_number == "1"
      return "#{day_number}st"
    elsif last_number == "2"
      return "#{day_number}nd"
    elsif last_number == "3"
      return "#{day_number}rd"
    else
      return "#{day_number}th"
    end
  end

  def today_highlighter(date)
    # here is the highlighter, change the string below to insert desired class in bootstrap
    "bg-warning text-dark" if date == Date.today
  end

  def grey_out_non_month(date)
    "bg-dark text-white" if date.month != @date.month
  end
end
