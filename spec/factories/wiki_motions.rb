# frozen_string_literal: true

FactoryBot.define do
  factory :wiki_motion do
    title { "An edited division" }
    description { "This division relates to all sorts of interesting things." }
    created_at { Time.zone.local(2014, 1, 1, 1, 1, 1) }
    association :user
    association :division
  end
end
