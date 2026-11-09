# frozen_string_literal: true

FactoryBot.define do
  factory :ai_division_summary do
    division
    model { "test.model-v1:0" }
    title { "Motions — Something" }
    description { "The Senate voted on something." }
  end
end
