# frozen_string_literal: true

Capybara.javascript_driver = :selenium_chrome_headless
Capybara.server = :webrick

# Selenium talks to the browser over local HTTP, so these must not be blocked
WebMock.disable_net_connect!(allow_localhost: true)
VCR.configure { |c| c.ignore_localhost = true }

RSpec.configure do |config|
  # Selenium Manager only ships x86 Linux binaries and Google publishes no Linux ARM Chrome, so :js specs can't start
  # a browser on ARM. The x86 CI job still runs them.
  config.filter_run_excluding js: true if RbConfig::CONFIG["host_cpu"].match?(/arm|aarch64/)

  config.include Warden::Test::Helpers, type: :feature

  config.after(type: :feature) do
    Warden.test_reset!
  end
end
