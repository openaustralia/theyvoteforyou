# frozen_string_literal: true

module CardScreenshotter
  # Raised when taking a screenshot of a card page fails. The original error
  # (e.g. Net::ReadTimeout) is available via #cause
  class ScreenshotError < StandardError; end
end
