# frozen_string_literal: true

module CardScreenshotter
  class Policies
    class << self
      include Rails.application.routes.url_helpers
      include PathHelper

      def run
        screenshotter = CardScreenshotter::Utils.new
        policies = Policy.all
        progress = ProgressBar.create(total: policies.count, format: "%t: |%B| %E %a")
        policies.each do |policy|
          screenshotter.screenshot_and_save(url(policy), save_path(policy))
          progress.increment
        end
        screenshotter.close_driver!
      end

      def url(policy)
        policy_url(policy, ActionMailer::Base.default_url_options.merge(card: true))
      end

      def save_path(policy)
        "public/cards#{policy_path(policy)}.png"
      end
    end
  end
end
