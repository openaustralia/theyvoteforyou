# frozen_string_literal: true

FactoryBot.define do
  factory :member_distance do
    association :member1, factory: :member
    association :member2, factory: :member
  end
end
