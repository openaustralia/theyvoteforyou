# frozen_string_literal: true

Capybara.javascript_driver = :selenium_chrome_headless
Capybara.server = :webrick

# Selenium talks to the browser over local HTTP, so these must not be blocked
WebMock.disable_net_connect!(allow_localhost: true)
VCR.configure { |c| c.ignore_localhost = true }

RSpec.configure do |config|
  config.include Warden::Test::Helpers, type: :feature

  config.after(type: :feature) do
    Warden.test_reset!
  end
end
