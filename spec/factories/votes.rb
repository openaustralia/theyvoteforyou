# frozen_string_literal: true

FactoryBot.define do
  factory :vote do
    association :member
    association :division
  end
end
