# frozen_string_literal: true

FactoryBot.define do
  factory :member do
    gid { "uk.org.publicwhip/lord/100156" }
    source_gid { "" }
    first_name { "Christine" }
    last_name { "Milne" }
    sequence(:title) { |n| "Title #{n}" }
    constituency { "Newtown" }
    party { "Australian Greens" }
    house { "representatives" }
    entered_house { "2005-07-01" }
    left_house { "9999-12-31" }
    entered_reason { "general_election" }
    left_reason { "still_in_office" }
    person
  end
end
