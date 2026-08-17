# frozen_string_literal: true

module CardScreenshotter
  class Utils
    CARD_WIDTH = 1200
    CARD_HEIGHT = 628
    RESTART_BROWSER_AFTER_NUMBER_OF_REQUESTS = 50
    # Transient errors (e.g. Net::ReadTimeout) get this many attempts, with a
    # browser restart in between, before the url is reported and skipped
    MAX_SCREENSHOT_ATTEMPTS = 3

    attr_reader :driver

    def initialize
      open_headless_driver!
    end

    # Restart the browser. This takes a little extra time but it helps to keep the memory usage
    # under control
    def restart_browser!
      close_driver!
      open_headless_driver!
    end

    def open_headless_driver!
      options = Selenium::WebDriver::Options.chrome(
        args: [
          "--headless=new",
          "--window-size=#{CARD_WIDTH},#{CARD_HEIGHT}"
        ]
      )
      @driver = Selenium::WebDriver.for :chrome, options: options
      adjust_window_for_viewport!
    end

    def close_driver!
      driver.quit
    end

    def screenshot_and_save(url, path)
      @count ||= 0
      # Restart the browser every certain number of requests
      if @count > RESTART_BROWSER_AFTER_NUMBER_OF_REQUESTS
        restart_browser!
        @count = 0
      end
      attempts = 0
      begin
        attempts += 1
        screenshot_and_save_without_restart(url, path)
      rescue ScreenshotError => e
        if attempts < MAX_SCREENSHOT_ATTEMPTS
          # A timeout can leave the browser session wedged, so start fresh
          restart_browser!
          retry
        end
        # Report and move on so one bad url doesn't abort the whole run
        Rails.logger.warn(e.message)
        Sentry.capture_exception(e) if defined?(Sentry) && Sentry.initialized?
      end
      @count += 1
    end

    def screenshot_and_save_without_restart(url, path)
      image = screenshot(url)
      save_image(image, path)
    end

    def screenshot(url)
      driver.get(url)
      driver.screenshot_as(:png)
    rescue StandardError => e
      # Include the failing url in the message. The original error is
      # preserved as the cause of the new exception
      raise ScreenshotError, "Error #{e} while screenshotting url: #{url}"
    end

    def save_image(image, path)
      FileUtils.mkdir_p(File.dirname(path))

      File.open(path, "wb+") do |f|
        f.write image
      end
    end

    # Selenium's resize_to adjusts the outer window, while screenshots use the viewport.
    # Align the viewport to the card size by compensating for browser chrome/frame size.
    def adjust_window_for_viewport!
      inner_width, inner_height, outer_width, outer_height = driver.execute_script(
        "return [window.innerWidth, window.innerHeight, window.outerWidth, window.outerHeight]"
      )
      return if inner_width == CARD_WIDTH && inner_height == CARD_HEIGHT

      width_delta = outer_width - inner_width
      height_delta = outer_height - inner_height
      driver.manage.window.resize_to(CARD_WIDTH + width_delta, CARD_HEIGHT + height_delta)
    end

    def self.external_screenshot_url(url)
      urlbox(
        url: url,
        # We're caching things for 1 day
        ttl: 1.day,
        width: CARD_WIDTH,
        height: CARD_HEIGHT
      )
    end

    # Given a url to screenshot (passed in options) this returns a URL that will be PNG image of that url using
    # the urlbox external service
    def self.urlbox(options = {}, format = "png")
      query_string = options.to_query
      # This HMAC essentially signs the query_string making it safe to share
      # this URL in public. An attacker can only request the same URL.
      # They can't create a screenshot of something else
      token = OpenSSL::HMAC.hexdigest("sha1", Rails.application.credentials.urlbox.secret!, query_string)

      "https://api.urlbox.io/v1/#{Rails.application.credentials.urlbox.apikey!}/#{token}/#{format}?#{query_string}"
    end
  end
end
