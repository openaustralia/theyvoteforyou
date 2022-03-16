# frozen_string_literal: true

FactoryBot.define do
  factory :division do
    date { Date.new(2014, 1, 1) }
    sequence(:number) { |n| n }
    house { "representatives" }
    name { "Some division" }
    motion { "I move that this division be very, very interesting" }
    source_url { "http://parlinfo.aph.gov.au/foobar" }
    debate_url { "http://parlinfo.aph.gov.au/bazbar" }
    debate_gid { "uk.org.publicwhip/representatives/2014-01-1.1.1" }

    after(:create) do |division|
      division.division_info = create(:division_info, division: division)
      division.whips = [create(:whip, division: division)]
      division.votes = [create(:vote, division: division)]
    end
  end
end
