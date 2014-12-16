FactoryGirl.define do
  factory :wiki_motion do
    title "An edited division"
    description "This division relates to all sorts of interesting things."
    edit_date Time.new(2014,1,1,1,1,1)
    user
    division
  end

  factory :user do
    sequence(:email) { |n| "henare#{n}@oaf.org.au" }
    password "password"
    sequence(:name) { |n| "Henare Degan #{n}" }
  end

  factory :division do
    date Date.new(2014,1,1)
    sequence(:number) { |n| n }
    house "representatives"
    name "Some division"
    motion "I move that this division be very, very interesting"
    source_url "http://parlinfo.aph.gov.au/foobar"
    debate_url "http://parlinfo.aph.gov.au/bazbar"
    source_gid "uk.org.publicwhip/representatives/2014-01-1.1.1"
    debate_gid "uk.org.publicwhip/representatives/2014-01-1.1.1"
  end

  factory :member do
    id "100156"
    gid "uk.org.publicwhip/lord/100156"
    source_gid ""
    first_name "Christine"
    last_name "Milne"
    title ""
    constituency "Tasmania"
    party "Australian Greens"
    house "senate"
    entered_house "2005-07-01"
    left_house "9999-12-31"
    entered_reason "general_election"
    left_reason "still_in_office"
    person_id "10458"
  end
end
