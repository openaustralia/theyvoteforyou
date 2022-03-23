# frozen_string_literal: true

FactoryBot.define do
  factory :member_info do
    association :member
    rebellions { 0 }
    tells { 0 }
    votes_attended { 0 }
    votes_possible { 0 }
    aye_majority { 0 }
  end
end
