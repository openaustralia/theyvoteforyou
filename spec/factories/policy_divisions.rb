# frozen_string_literal: true

FactoryBot.define do
  factory :policy_division do
    policy
    division
    vote { "aye" }
  end
end
