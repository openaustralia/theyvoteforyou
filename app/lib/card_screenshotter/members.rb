# frozen_string_literal: true

module CardScreenshotter
  class Members
    class << self
      include Rails.application.routes.url_helpers
      include PathHelper

      def update_screenshots_policy_votes
        screenshotter = CardScreenshotter::Utils.new
        ppds = PolicyPersonDistance.all
        progress = ProgressBar.create(title: "Members votes on policies screenshots", total: ppds.count, format: "%t: |%B| %E %a")
        ppds.find_each do |ppd|
          screenshotter.screenshot_and_save(url_person_policy(ppd), save_path_person_policy(ppd))
          progress.increment
        end
        screenshotter.close_driver!
      end

      def update_screenshots_members
        screenshotter = CardScreenshotter::Utils.new
        members = Member.all
        progress = ProgressBar.create(title: "Members page screenshots", total: members.count, format: "%t: |%B| %E %a")
        members.each do |member|
          screenshotter.screenshot_and_save(url_member(member), save_path_member(member))
          progress.increment
        end
        screenshotter.close_driver!
      end

      def url_member(member)
        member_url(member.url_params.merge(ActionMailer::Base.default_url_options.merge(card: true)))
      end

      def url_person_policy(ppd)
        person_policy_url_simple(ppd.person, ppd.policy, ActionMailer::Base.default_url_options.merge(card: true))
      end

      def save_path_person_policy(ppd)
        "public/cards#{person_policy_path_simple(ppd.person, ppd.policy)}.png"
      end

      def save_path_member(member)
        "public/cards#{member_path_simple(member)}.png"
      end
    end
  end
end
