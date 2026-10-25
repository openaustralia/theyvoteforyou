# frozen_string_literal: true

module DivisionSummaryPipeline
  # Hansard and TVFY write the same moment several ways: a speech's time attribute is "13:27"
  # or "13:27:00", DataLoader::DivisionXml#clock_time pads the hour to three digits
  # ("013:31:00"), and Division#clock_time prints " 1:31 PM" with a space-padded hour. This is
  # the one place those are read, so a quote's time and the division's time are always printed
  # the same way.
  module ClockTime
    TWELVE_HOUR = /(\d{1,2}):(\d{2})(?::\d{2})?\s*([AP]M)/i
    TWENTY_FOUR_HOUR = /(\d{1,3}):(\d{2})/

    module_function

    # "13:31", for comparing times; "" when the value is not a time.
    def normalise(value)
      hour, minute = hour_and_minute(value)
      hour ? format("%<hour>02d:%<minute>02d", hour: hour, minute: minute) : ""
    end

    # "1:31 PM", for printing; the value unchanged (stripped) when it is not a time.
    def display(value)
      hour, minute = hour_and_minute(value)
      return value.to_s.strip unless hour

      meridiem = hour >= 12 ? "PM" : "AM"
      "#{((hour - 1) % 12) + 1}:#{minute.to_s.rjust(2, '0')} #{meridiem}"
    end

    def hour_and_minute(value)
      text = value.to_s.strip
      if (match = text.match(TWELVE_HOUR))
        hour = match[1].to_i % 12
        hour += 12 if match[3].casecmp?("PM")
        [hour, match[2].to_i]
      elsif (match = text.match(TWENTY_FOUR_HOUR))
        [match[1].to_i, match[2].to_i]
      end
    end
  end
end
