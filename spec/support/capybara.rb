# frozen_string_literal: true

Capybara.javascript_driver = :selenium_chrome_headless

# In a Docker container (`make test`), Chrome's sandbox lacks the kernel features it needs and /dev/shm is too small,
# so Chrome exits on start. Elsewhere, including CI, the sandbox stays on.
if File.exist?("/.dockerenv")
  Capybara.register_driver :selenium_chrome_headless do |app|
    options = Selenium::WebDriver::Chrome::Options.new(args: %w[--headless=new --no-sandbox --disable-dev-shm-usage])
    Capybara::Selenium::Driver.new(app, browser: :chrome, options:)
  end
end
Capybara.server = :webrick

# Selenium talks to the browser over local HTTP, so these must not be blocked
WebMock.disable_net_connect!(allow_localhost: true)
VCR.configure { |c| c.ignore_localhost = true }

RSpec.configure do |config|
  # Selenium Manager only ships x86 Linux binaries and Google publishes no Linux ARM Chrome, so :js specs can't start
  # a browser on Linux ARM. macOS on Apple Silicon is fine, and so is the x86 CI job.
  config.filter_run_excluding js: true if RbConfig::CONFIG["host_cpu"].match?(/arm|aarch64/) && RbConfig::CONFIG["host_os"].match?(/linux/)

  config.include Warden::Test::Helpers, type: :feature

  config.after(type: :feature) do
    Warden.test_reset!
  end
end
