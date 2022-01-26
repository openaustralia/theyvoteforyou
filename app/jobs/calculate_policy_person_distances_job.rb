# frozen_string_literal: true

class CalculatePolicyPersonDistancesJob < ApplicationJob
  queue_as :default

  def perform(policy)
    policy.calculate_person_distances!
  end
end
