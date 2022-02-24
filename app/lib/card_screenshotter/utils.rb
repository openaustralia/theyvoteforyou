# frozen_string_literal: true

require "selenium-webdriver"
require "fileutils"

module CardScreenshotter
  class Utils
    class << self
      def open_headless_driver
        options = Selenium::WebDriver::Chrome::Options.new
        options.add_argument("--headless")
        Selenium::WebDriver.for :chrome, capabilities: [options]
      end

      def close_driver(driver)
        driver.quit
      end

      def screenshot(driver, url, width, height)
        driver.get(url)
        driver.manage.window.resize_to(width, height)
        driver.screenshot_as(:png)
      end

      def save_image(image, save_path, file_name)
        FileUtils.mkdir_p(save_path) unless File.directory?(save_path)

        File.open("#{save_path}/#{file_name}", "wb+") do |f|
          f.write image
        end
      end
    end
  end
end
