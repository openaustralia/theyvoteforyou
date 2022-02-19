# frozen_string_literal: true

class AlertWatchesJob < ApplicationJob
  queue_as :default

  def perform(policy, version)
    policy.watches.each do |watch|
      AlertMailer.policy_updated(policy, version, watch.user).deliver
    end
  end
end
