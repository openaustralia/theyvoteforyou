# frozen_string_literal: true

FactoryBot.define do
  factory :people_distance do
    association :person1, factory: :person
    association :person2, factory: :person
    nvotessame { 0 }
    nvotesdiffer { 0 }
    distance_b { 0 }
  end
end
