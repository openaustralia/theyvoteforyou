# frozen_string_literal: true

FactoryBot.define do
  factory :wiki_motion do
    title { "An edited division" }
    description { "This division relates to all sorts of interesting things." }
    created_at { Time.zone.local(2014, 1, 1, 1, 1, 1) }
    association :user
    association :division
  end

  factory :user do
    sequence(:email) { |n| "henare#{n}@oaf.org.au" }
    password { "password" }
    sequence(:name) { |n| "Henare Degan #{n}" }
  end

  factory :division do
    date { Date.new(2014, 1, 1) }
    sequence(:number) { |n| n }
    house { "representatives" }
    name { "Some division" }
    motion { "I move that this division be very, very interesting" }
    source_url { "http://parlinfo.aph.gov.au/foobar" }
    debate_url { "http://parlinfo.aph.gov.au/bazbar" }
    source_gid { "uk.org.publicwhip/representatives/2014-01-1.1.1" }
    debate_gid { "uk.org.publicwhip/representatives/2014-01-1.1.1" }

    after(:create) do |division|
      division.division_info = create(:division_info, division: division)
      division.whips = [create(:whip, division: division)]
      division.votes = [create(:vote, division: division)]
    end
  end

  factory :whip do
    association :division
    sequence(:party) { |n| "Party #{n}" }
    aye_votes { 5 }
    aye_tells { 5 }
    no_votes { 3 }
    no_tells { 3 }
    both_votes { 1 }
    abstention_votes { 0 }
    possible_votes { 20 }
    whip_guess { "guess" }
  end

  factory :division_info do
    association :division
    rebellions { 3 }
    tells { 4 }
    turnout { 5 }
    possible_turnout { 6 }
    aye_majority { 7 }
  end

  factory :vote do
    association :member
    association :division
  end

  factory :member do
    gid { "uk.org.publicwhip/lord/100156" }
    source_gid { "" }
    first_name { "Christine" }
    last_name { "Milne" }
    sequence(:title) { |n| "Title #{n}" }
    constituency { "Newtown" }
    party { "Australian Greens" }
    house { "representatives" }
    entered_house { "2005-07-01" }
    left_house { "9999-12-31" }
    entered_reason { "general_election" }
    left_reason { "still_in_office" }
    # TODO: Why are we using person_id here rather than person?
    person_id { "10458" }
  end

  factory :policy do
    sequence(:name) { |n| "the existence of test policies #{n}" }
    description { "there should be fabulous test policies" }
    private { 0 }
    association :user

    factory :provisional_policy do
      private { 2 }
    end
  end

  factory :policy_person_distance do
    association :policy
    association :person
  end

  factory :person
end
