# frozen_string_literal: true

require "selenium-webdriver"
require "fileutils"

module CardScreenshotter
  class Utils
    class << self
      CARD_WIDTH = 600
      CARD_HEIGHT = 350

      def open_headless_driver
        options = Selenium::WebDriver::Chrome::Options.new
        options.add_argument("--headless")
        driver = Selenium::WebDriver.for :chrome, capabilities: [options]
        driver.manage.window.resize_to(CARD_WIDTH, CARD_HEIGHT)
        driver
      end

      def close_driver(driver)
        driver.quit
      end

      def screenshot(driver, url)
        driver.get(url)
        driver.screenshot_as(:png)
      end

      def save_image(image, save_path, file_name)
        FileUtils.mkdir_p(save_path)

        File.open("#{save_path}/#{file_name}", "wb+") do |f|
          f.write image
        end
      end
    end
  end
end
