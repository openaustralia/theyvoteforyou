# frozen_string_literal: true

class AlertWatchesJob < ApplicationJob
  queue_as :default

  def perform(policy, version)
    policy.watches.each do |watch|
      # Workaround for problem where a small number of users' email has been set to nil
      # https://github.com/openaustralia/publicwhip/issues/1344
      AlertMailer.policy_updated(policy, version, watch.user).deliver if watch.user.email.present?
    end
  end
end
