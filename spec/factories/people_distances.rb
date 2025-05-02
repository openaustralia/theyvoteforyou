# frozen_string_literal: true

FactoryBot.define do
  factory :people_distance do
    person1 factory: %i[person]
    person2 factory: %i[person]
    nvotessame { 0 }
    nvotesdiffer { 0 }
    distance_b { 0 }
  end
end
