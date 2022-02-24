# frozen_string_literal: true

include Rails.application.routes.url_helpers

module CardScreenshotter
  class Members
    def self.update_screenshots
      driver = CardScreenshotter::Utils.open_headless_driver

      card_width = 600
      card_height = 350
      save_path = Rails.root.join("public/cards/member_policy_vote")

      PolicyPersonDistance.find_each do |ppd|
        person = ppd.person
        policy = ppd.policy
        url = "http://#{ActionMailer::Base.default_url_options[:host]}#{person_policy_path_simple(person, policy)}?card=true"
        file_name = person_policy_path_simple(person, policy).gsub("/", "_")
        file_name = "#{file_name}.png"

        image = CardScreenshotter::Utils.screenshot(driver, url, card_width, card_height)
        CardScreenshotter::Utils.save_image(image, save_path, file_name)
      end
      CardScreenshotter::Utils.close_driver(driver)
    end
  end
end
