# frozen_string_literal: true

module CardScreenshotter
  class Members
    def self.update_screenshots
      driver = CardScreenshotter::Utils.open_headless_driver
      ppds = PolicyPersonDistance.all
      progress = ProgressBar.create(title: "Members screenshots", total: ppds.count, format: "%t: |%B| %E %a")
      ppds.find_each do |ppd|
        update_screenshot(driver, ppd)
        progress.increment
      end
      CardScreenshotter::Utils.close_driver(driver)
    end

    def self.update_screenshot(driver, ppd)
      person = ppd.person
      policy = ppd.policy
      CardScreenshotter::Utils.screenshot_and_save(driver, url(person, policy), save_path(person, policy))
    end

    def self.url(person, policy)
      # TODO: Make this work in development and production
      "https://#{ActionMailer::Base.default_url_options[:host]}#{person_policy_path_simple(person, policy)}?card=true"
    end

    def self.save_path(person, policy)
      "public/cards#{person_policy_path_simple(person, policy)}.png"
    end
  end
end
