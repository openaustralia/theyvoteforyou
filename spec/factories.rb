FactoryGirl.define do
  factory :electorate do
    id 1
    name "Warringah"
    main_name "true"
    from_date "1000-1-1"
    to_date "9999-12-31"
    house "representatives"
  end

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

    after(:create) do |division|
      division.division_info create(:division_info, division: division)
      division.whips = [create(:whip, division: division)]
      division.votes = [create(:vote, division: division)]
    end
  end

  factory :whip do
    division
    sequence(:party) { |n| "Party #{n}" }
    aye_votes 5
    aye_tells 5
    no_votes 3
    no_tells 3
    both_votes 1
    abstention_votes 0
    possible_votes 20
    whip_guess "guess"
  end

  factory :division_info do
    division
    rebellions 3
    tells 4
    turnout 5
    possible_turnout 6
    aye_majority 7
  end

  factory :vote do
    member
    division
  end

  factory :division_info do
    division
    rebellions 0
    tells 0
    turnout 136
    possible_turnout 150
    aye_majority -1
  end

  factory :vote do
    division
    member_id 100156
    vote 'yes'
    teller false
  end

  factory :whip do
    division
    party "Australian Labor Party"
    aye_votes 0
    aye_tells 0
    no_votes 1
    no_tells 0
    both_votes 0
    abstention_votes 0
    possible_votes 1
    whip_guess "no"
  end

  factory :member do
    gid "uk.org.publicwhip/lord/100156"
    source_gid ""
    first_name "Christine"
    last_name "Milne"
    sequence(:title) { |n| "Title #{n}" }
    constituency "Newtown"
    party "Australian Greens"
    house "representatives"
    entered_house "2005-07-01"
    left_house "9999-12-31"
    entered_reason "general_election"
    left_reason "still_in_office"
    person_id "10458"
  end

  factory :member_info do
    member_id 1
    rebellions 0
    tells 0
    votes_attended 1
    votes_possible 2
    aye_majority 1
  end

  factory :member_distance do
    member1_id 1
    member2_id 265
    nvotessame 0
    nvotesdiffer 0
    nvotesabsent 0
    distance_a -1.0
    distance_b -1.0
  end

  factory :policy_person_distance do
    policy_id 1
    person_id 10552
    nvotessame 0
    nvotessamestrong 0
    nvotesdiffer 1
    nvotesdifferstrong 0
    nvotesabsent 0
    nvotesabsentstrong 0
    distance_a 1.0
    distance_b 1.0
  end

  factory :person do
    small_image_url "http://www.openaustralia.org/images/mps/10458.jpg"
    large_image_url "http://www.openaustralia.org/images/mpsL/10458.jpg"
    id 10458
  end

  factory :policy do
    sequence(:name) { |n| "the existence of test policies #{n}" }
    description 'there should be fabulous test policies'
    private 0
    user

    factory :provisional_policy do
      private 2
    end
  end

  factory :policy_division do
    division
    policy
    vote "aye"
  end

  factory :office do
    id 123
    position "Minister for Silly Walks"
    from_date "2015-08-03"
    to_date "2017-04-23"
    person_id 10001
    dept ""
    responsibility ""
  end
end
