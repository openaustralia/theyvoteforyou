# frozen_string_literal: true

FactoryBot.define do
  factory :policy_person_distance do
    policy
    person
    nvotessame { 0 }
    nvotessamestrong { 0 }
    nvotesdiffer { 0 }
    nvotesdifferstrong { 0 }
    nvotesabsent { 0 }
    nvotesabsentstrong { 0 }
  end
end
