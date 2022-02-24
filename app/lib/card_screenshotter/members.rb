# frozen_string_literal: true

include Rails.application.routes.url_helpers

module CardScreenshotter
  class Members
    def self.update_screenshots
      driver = CardScreenshotter::Utils.open_headless_driver

      card_width = 600
      card_height = 350

      PolicyPersonDistance.find_each do |ppd|
        person = ppd.person
        policy = ppd.policy
        url = "https://#{ActionMailer::Base.default_url_options[:host]}#{person_policy_path_simple(person, policy)}?card=true"
        save_path = get_save_path(person)
        file_name = "#{policy.id}.png"

        image = CardScreenshotter::Utils.screenshot(driver, url, card_width, card_height)
        CardScreenshotter::Utils.save_image(image, save_path, file_name)
      end
      CardScreenshotter::Utils.close_driver(driver)
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
