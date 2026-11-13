# frozen_string_literal: true

FactoryBot.define do
  factory :announcement do
    body { "The site will be briefly offline for maintenance." }
    published { true }
  end
end
