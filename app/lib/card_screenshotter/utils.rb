# frozen_string_literal: true

module CardScreenshotter
  class Utils
    CARD_WIDTH = 1200
    CARD_HEIGHT = 628
    RESTART_BROWSER_AFTER_NUMBER_OF_REQUESTS = 50

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
      options = Selenium::WebDriver::Chrome::Options.new
      options.add_argument("--headless")
      @driver = Selenium::WebDriver.for :chrome, capabilities: [options]
      driver.manage.window.resize_to(CARD_WIDTH, CARD_HEIGHT)
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
      screenshot_and_save_without_restart(url, path)
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
      # Make the error a little more useful by including the failing url
      raise "Error #{e} while screenshotting url: #{url}"
    end

    def save_image(image, path)
      FileUtils.mkdir_p(File.dirname(path))

      File.open(path, "wb+") do |f|
        f.write image
      end
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
      token = OpenSSL::HMAC.hexdigest("sha1", Rails.application.secrets.urlbox_secret, query_string)

      "https://api.urlbox.io/v1/#{Rails.application.secrets.urlbox_apikey}/#{token}/#{format}?#{query_string}"
    end
  end
end
