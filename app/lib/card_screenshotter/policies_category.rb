# frozen_string_literal: true

module CardScreenshotter
  class PoliciesCategory
    class << self
      include Rails.application.routes.url_helpers
      include PathHelper

      def run
        screenshotter = CardScreenshotter::Utils.new
        policies = Policy.all
        number_of_images = PolicyPersonDistance.all_categories.count * policies.count
        progress = ProgressBar.create(title: "Policies screenshots per voting category", total: number_of_images, format: "%t: |%B| %E %a")
        policies.each do |policy|
          PolicyPersonDistance.all_categories.each do |category|
            screenshotter.screenshot_and_save(url(policy, category), save_path(policy, category))
            progress.increment
          end
        end
        screenshotter.close_driver!
      end

      def url(policy, category)
        policy_url(policy, ActionMailer::Base.default_url_options.merge(card: true, category: category))
      end

      def save_path(policy, category)
        "public/cards#{policy_path(policy)}/categories/#{category}.png"
      end
    end
  end
end
