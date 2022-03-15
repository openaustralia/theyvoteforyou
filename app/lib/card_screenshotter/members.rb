# frozen_string_literal: true

module CardScreenshotter
  class Members
    class << self
      include Rails.application.routes.url_helpers
      include PathHelper
      CARD_WIDTH = 600
      CARD_HEIGHT = 350

      def update_screenshots
        screenshotter = CardScreenshotter::Utils.new(CARD_WIDTH, CARD_HEIGHT)
        ppds = PolicyPersonDistance.all
        progress = ProgressBar.create(title: "Members screenshots", total: ppds.count, format: "%t: |%B| %E %a")
        ppds.find_each do |ppd|
          update_screenshot(screenshotter, ppd)
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
