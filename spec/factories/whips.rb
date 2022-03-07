# frozen_string_literal: true

FactoryBot.define do
  factory :whip do
    association :division
    sequence(:party) { |n| "Party #{n}" }
    aye_votes { 5 }
    aye_tells { 5 }
    no_votes { 3 }
    no_tells { 3 }
    both_votes { 1 }
    abstention_votes { 0 }
    possible_votes { 20 }
    whip_guess { "guess" }
  end
end
