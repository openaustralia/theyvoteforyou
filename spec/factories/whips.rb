# frozen_string_literal: true

FactoryBot.define do
  factory :whip do
    division
    sequence(:party) { |n| "Party #{n}" }
    aye_votes { 0 }
    aye_tells { 0 }
    no_votes { 0 }
    no_tells { 0 }
    both_votes { 0 }
    abstention_votes { 0 }
    possible_votes { 0 }
    whip_guess { "unknown" }
  end
end
