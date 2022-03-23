# frozen_string_literal: true

module CardScreenshotter
  class Members
    class << self
      include Rails.application.routes.url_helpers
      include PathHelper

      def run
        screenshotter = CardScreenshotter::Utils.new
        people = Person.all
        progress = ProgressBar.create(title: "Members page screenshots", total: people.count, format: "%t: |%B| %E %a")
        people.each do |person|
          member = person.latest_member
          screenshotter.screenshot_and_save(url(member), save_path(member))
          progress.increment
        end
        screenshotter.close_driver!
      end

      def url(member)
        member_url(member.url_params.merge(ActionMailer::Base.default_url_options.merge(card: true)))
      end

      def save_path(member)
        "public/cards#{member_path_simple(member)}.png"
      end
    end
  end
end
