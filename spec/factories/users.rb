# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "henare#{n}@oaf.org.au" }
    password { "password" }
    name { "Henare Degan" }

    factory :confirmed_user do
      confirmed_at { Time.zone.now }
    end
  end
end
