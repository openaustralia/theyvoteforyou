# frozen_string_literal: true

module CardScreenshotter
  class Utils
    class << self
      def open_headless_driver(card_width, card_height)
        options = Selenium::WebDriver::Chrome::Options.new
        options.add_argument("--headless")
        driver = Selenium::WebDriver.for :chrome, capabilities: [options]
        driver.manage.window.resize_to(card_width, card_height)
        driver
      end

      def close_driver(driver)
        driver.quit
      end

      def screenshot_and_save(driver, url, path)
        image = screenshot(driver, url)
        save_image(image, path)
      end

      def screenshot(driver, url)
        driver.get(url)
        driver.screenshot_as(:png)
      end

      def save_image(image, path)
        FileUtils.mkdir_p(File.dirname(path))

        File.open(path, "wb+") do |f|
          f.write image
        end
      end
    end
  end
end
