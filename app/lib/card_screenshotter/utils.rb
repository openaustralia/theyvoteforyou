# frozen_string_literal: true

module CardScreenshotter
  class Utils
    CARD_WIDTH = 600
    CARD_HEIGHT = 350
    attr_reader :driver

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
  end
end
