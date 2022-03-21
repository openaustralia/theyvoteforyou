# frozen_string_literal: true

module CardScreenshotter
  class PersonPolicies
    class << self
      include Rails.application.routes.url_helpers
      include PathHelper

      def run
        screenshotter = CardScreenshotter::Utils.new
        ppds = PolicyPersonDistance.all
        progress = ProgressBar.create(title: "Members votes on policies screenshots", total: ppds.count, format: "%t: |%B| %E %a")
        ppds.find_each do |ppd|
          screenshotter.screenshot_and_save(url(ppd), save_path(ppd))
          progress.increment
        end
        screenshotter.close_driver!
      end

      def url(ppd)
        person_policy_url_simple(ppd.person, ppd.policy, ActionMailer::Base.default_url_options.merge(card: true))
      end

      def save_path(ppd)
        "public/cards#{person_policy_path_simple(ppd.person, ppd.policy)}.png"
      end
    end
  end
end
