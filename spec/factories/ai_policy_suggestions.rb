# frozen_string_literal: true

FactoryBot.define do
  factory :ai_policy_suggestion do
    division
    policy
    model { "test.model-v1:0" }
    match { "existing" }
    direction { "for" }
    reasoning { "because the test says so" }
  end
end
