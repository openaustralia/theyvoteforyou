# frozen_string_literal: true

module CardScreenshotter
  class MemberPolicyCategory
    class << self
      include Rails.application.routes.url_helpers
      include PathHelper

      def run
        screenshotter = CardScreenshotter::Utils.new
        people = Person.all
        number_of_images = people.count * PolicyPersonDistance.all_categories.count
        progress = ProgressBar.create(title: "Members policies per category screenshots", total: number_of_images, format: "%t: |%B| %E %a")
        people.each do |person|
          # Only do screenshots for the latest member for each person. Because every other member gets redirected to the "latest member"
          # in the web application
          member = person.latest_member
          PolicyPersonDistance.all_categories.each do |category|
            screenshotter.screenshot_and_save(url(member, category), save_path(member, category))
            progress.increment
          end
        end
        screenshotter.close_driver!
      end

      def url(member, category)
        member_url(member.url_params.merge(ActionMailer::Base.default_url_options.merge(card: true, category: category)))
      end

      def save_path(member, category)
        "public/cards#{member_path_simple(member)}/categories/#{category}.png"
      end
    end
  end
end
