# frozen_string_literal: true

FactoryBot.define do
  factory :division_info do
    association :division
    rebellions { 3 }
    tells { 4 }
    turnout { 5 }
    possible_turnout { 6 }
    aye_majority { 7 }
  end
end
