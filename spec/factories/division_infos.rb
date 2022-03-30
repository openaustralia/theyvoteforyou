# frozen_string_literal: true

FactoryBot.define do
  factory :division_info do
    association :division
    rebellions { 0 }
    tells { 0 }
    turnout { 0 }
    possible_turnout { 0 }
    aye_majority { 0 }
  end
end
