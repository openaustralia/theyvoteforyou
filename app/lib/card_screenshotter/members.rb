# frozen_string_literal: true

include Rails.application.routes.url_helpers

module CardScreenshotter
  class Members
    CARD_WIDTH = 600
    CARD_HEIGHT = 350

    def self.update_screenshots
      driver = CardScreenshotter::Utils.open_headless_driver
      PolicyPersonDistance.find_each { |ppd| update_screenshot(driver, ppd) }
      CardScreenshotter::Utils.close_driver(driver)
    end

    def self.update_screenshot(driver, ppd)
      person = ppd.person
      policy = ppd.policy
      url = "https://#{ActionMailer::Base.default_url_options[:host]}#{person_policy_path_simple(person, policy)}?card=true"
      save_path = get_save_path(person)
      file_name = "#{policy.id}.png"

      image = CardScreenshotter::Utils.screenshot(driver, url, CARD_WIDTH, CARD_HEIGHT)
      CardScreenshotter::Utils.save_image(image, save_path, file_name)
    end

    def self.get_save_path(person)
      member = person.latest_member
      house = member.house.downcase
      constituency = member.constituency.downcase
      name = member.first_name.concat("_", member.last_name).downcase
      "public/cards/people/#{house}/#{constituency}/#{name}/policies"
    end
  end
end
