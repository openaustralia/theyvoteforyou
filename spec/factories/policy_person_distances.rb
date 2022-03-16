# frozen_string_literal: true

FactoryBot.define do
  factory :policy_person_distance do
    association :policy
    association :person
  end
end
