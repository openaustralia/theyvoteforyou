# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "henare#{n}@oaf.org.au" }
    password { "password" }
    name { "Henare Degan" }
  end
end
