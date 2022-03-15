# frozen_string_literal: true

module CardScreenshotter
  class Members
    class << self
      include Rails.application.routes.url_helpers
      include PathHelper

      def update_screenshots
        screenshotter = CardScreenshotter::Utils.new
        screenshotter.open_headless_driver!
        ppds = PolicyPersonDistance.all
        progress = ProgressBar.create(title: "Members screenshots", total: ppds.count, format: "%t: |%B| %E %a")
        count = 0
        ppds.find_each do |ppd|
          # Close and restart chrome every 50 requests
          if count > 50
            screenshotter.close_driver!
            screenshotter.open_headless_driver!
            count = 0
          end
          update_screenshot(screenshotter, ppd)
          count += 1
          progress.increment
        end
        screenshotter.close_driver!
      end

      def update_screenshot(screenshotter, ppd)
        screenshotter.screenshot_and_save(url(ppd), save_path(ppd))
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
