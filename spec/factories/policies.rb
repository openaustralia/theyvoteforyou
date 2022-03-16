# frozen_string_literal: true

FactoryBot.define do
  factory :policy do
    sequence(:name) { |n| "the existence of test policies #{n}" }
    description { "there should be fabulous test policies" }
    private { 0 }
    association :user

    factory :provisional_policy do
      private { 2 }
    end
  end
end
