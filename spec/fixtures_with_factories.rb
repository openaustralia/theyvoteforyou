# frozen_string_literal: true

# Everything is a temporary workaround as a step towards moving away from using fixtures to just using factory bot.
# Here's we're basically recreating the entire fixtures set in one big lump

RSpec.shared_context "with fixtures" do
  def remove_old_fixtures
    DivisionInfo.delete_all
    Division.delete_all
    Electorate.delete_all
    MemberDistance.delete_all
    MemberInfo.delete_all
    Member.delete_all
    Office.delete_all
    Person.delete_all
    Policy.delete_all
    PolicyDivision.delete_all
    PolicyPersonDistance.delete_all
    User.delete_all
    Vote.delete_all
    Whip.delete_all
    WikiMotion.delete_all
  end

  def add_new_fixtures
    divisions_fixtures
    users_fixtures
    people_fixtures
    members_fixtures
    policies_fixtures
    member_infos_fixtures
    member_distances_fixtures
    policy_person_distances_fixtures
    offices_fixtures
  end

  def divisions_fixtures
    division_representatives_2013_3_14_1
    division_senate_2013_3_14_1
    division_representatives_2006_12_06_3
    division_senate_2009_11_25_8
    division_senate_2009_11_30_8
    division_senate_2009_12_30_8
  end

  def users_fixtures
    user
  end

  def policies_fixtures
    policy1
    policy2
    policy3
  end

  def people_fixtures
    person_tony_abbott
    person_kevin_rudd
    person_christine_milne
    person_john_howard
    person_maxine_mckew
    person_john_alexander
    person_christopher_back
    person_judith_adams
    person_paul_zammit
    person_disagreeable_curmudgeon
    person_surly_nihilist
    person_roger_price
  end

  def members_fixtures
    member_tony_abbott
    member_kevin_rudd
    member_christine_milne
    member_john_howard
    member_maxine_mckew
    member_john_alexander
    member_christopher_back
    member_judith_adams
    member_paul_zammit
    member_disagreeable_curmudgeon
    member_surly_nihilist
    member_roger_price
  end

  let(:division_representatives_2013_3_14_1) do
    division = create(
      :division,
      id: 1,
      date: "2013-3-14",
      clock_time: "010:56:00",
      number: 1,
      house: "representatives",
      name: "Bills &#8212; National Disability Insurance Scheme Bill 2012; Consideration in Detail",
      source_url: "http://parlinfo.aph.gov.au/parlInfo/search/display/display.w3p;adv=yes;orderBy=_fragment_number,doc_date-rev;page=0;query=Dataset%3Ahansardr,hansardr80%20Date%3A14%2F3%2F2013;rec=0;resCount=Default",
      debate_url: "",
      motion: '<p class="speaker">Jenny Macklin</p><p>I present a supplementary explanatory memorandum to the bill and ask leave of the House to move government amendments (1) to (77), as circulated, together.</p>',
      debate_gid: "uk.org.publicwhip/debate/2013-03-14.17.1"
    )
    create(
      :division_info,
      division_id: division.id,
      rebellions: 0,
      tells: 0,
      turnout: 136,
      possible_turnout: 150,
      aye_majority: -1
    )
    create(
      :whip,
      division_id: division.id,
      party: "Australian Labor Party",
      aye_votes: 0,
      aye_tells: 0,
      no_votes: 1,
      no_tells: 0,
      both_votes: 0,
      abstention_votes: 0,
      possible_votes: 1,
      whip_guess: "no"
    )
    create(
      :whip,
      division_id: division.id,
      party: "Liberal Party",
      aye_votes: 0,
      aye_tells: 0,
      no_votes: 0,
      no_tells: 0,
      both_votes: 0,
      abstention_votes: 0,
      possible_votes: 1,
      whip_guess: "unknown"
    )
    text_body = <<~TEXT
      --- DIVISION TITLE ---

      test

      --- MOTION EFFECT ---

      This is some test text.

      It might relate to bills containing HTML characters like the Carbon Pollution Reduction Scheme Bill&#160;2009 and Bills &#8212; National Disability Insurance Scheme Bill
      --- COMMENTS AND NOTES ---

      (put thoughts and notes for other researchers here)
    TEXT
    create(
      :wiki_motion,
      id: 1,
      division_id: division.id,
      text_body: text_body,
      user_id: user.id,
      created_at: "2013-10-20 00:12:13"
    )
    create(
      :vote,
      division_id: division.id,
      member_id: member_kevin_rudd.id,
      vote: "no",
      teller: false
    )
    division
  end

  let(:division_senate_2013_3_14_1) do
    division = create(
      :division,
      id: 9,
      date: "2013-3-14",
      number: 1,
      house: "senate",
      name: "Motions &#8212; Renewable Energy Certificates",
      source_url: "http://aph.gov.au/somedebate",
      debate_url: "",
      motion: "",
      debate_gid: "uk.org.publicwhip/lords/2013-03-14.22.1"
    )
    create(
      :division_info,
      division_id: division.id,
      rebellions: 0,
      tells: 0,
      turnout: 69,
      possible_turnout: 88,
      aye_majority: -3
    )
    create(
      :whip,
      division_id: division.id,
      party: "Australian Greens",
      aye_votes: 0,
      aye_tells: 0,
      no_votes: 1,
      no_tells: 0,
      both_votes: 0,
      abstention_votes: 0,
      possible_votes: 1,
      whip_guess: "no"
    )
    create(
      :vote,
      division_id: division.id,
      member_id: member_christine_milne.id,
      vote: "no",
      teller: false
    )
    division
  end

  let(:division_representatives_2006_12_06_3) do
    division = create(
      :division,
      id: 347,
      date: "2006-12-06",
      clock_time: "019:29:00",
      number: 3,
      house: "representatives",
      name: "Prohibition of Human Cloning for Reproduction and the Regulation of Human Embryo Research Amendment Bill 2006 &#8212; Consideration in Detail",
      source_url: "http://parlinfo.aph.gov.au/parlInfo/search/display/display.w3p;query=Id:chamber/hansardr/2006-12-06/0000",
      debate_url: "http://parlinfo.aph.gov.au/parlInfo/search/display/display.w3p;query=Id:chamber/hansardr/2006-12-06/0000",
      motion: '<p pwmotiontext="moved">That the amendments (<b>Mr Michael Ferguson&#8217;s</b>) be agreed to.</p>',
      debate_gid: "uk.org.publicwhip/debate/2006-12-06.98.1"
    )
    create(
      :division_info,
      division_id: division.id,
      rebellions: 0,
      tells: 4,
      turnout: 129,
      possible_turnout: 150,
      aye_majority: -23
    )
    create(
      :whip,
      division_id: division.id,
      party: "Australian Labor Party",
      aye_votes: 6,
      aye_tells: 1,
      no_votes: 40,
      no_tells: 1,
      both_votes: 0,
      abstention_votes: 0,
      possible_votes: 59,
      whip_guess: "none"
    )
    create(
      :whip,
      division_id: division.id,
      party: "Country Liberal Party",
      aye_votes: 0,
      aye_tells: 0,
      no_votes: 0,
      no_tells: 0,
      both_votes: 0,
      abstention_votes: 0,
      possible_votes: 1,
      whip_guess: "unknown"
    )
    create(
      :whip,
      division_id: division.id,
      party: "CWM",
      aye_votes: 0,
      aye_tells: 0,
      no_votes: 0,
      no_tells: 0,
      both_votes: 0,
      abstention_votes: 0,
      possible_votes: 1,
      whip_guess: "none"
    )
    create(
      :whip,
      division_id: division.id,
      party: "Independent",
      aye_votes: 3,
      aye_tells: 0,
      no_votes: 0,
      no_tells: 0,
      both_votes: 0,
      abstention_votes: 0,
      possible_votes: 4,
      whip_guess: "none"
    )
    create(
      :whip,
      division_id: division.id,
      party: "Liberal Party",
      aye_votes: 33,
      aye_tells: 0,
      no_votes: 33,
      no_tells: 1,
      both_votes: 0,
      abstention_votes: 0,
      possible_votes: 73,
      whip_guess: "none"
    )
    create(
      :whip,
      division_id: division.id,
      party: "National Party",
      aye_votes: 9,
      aye_tells: 1,
      no_votes: 1,
      no_tells: 0,
      both_votes: 0,
      abstention_votes: 0,
      possible_votes: 11,
      whip_guess: "none"
    )
    create(
      :whip,
      division_id: division.id,
      party: "SPK",
      aye_votes: 0,
      aye_tells: 0,
      no_votes: 0,
      no_tells: 0,
      both_votes: 0,
      abstention_votes: 0,
      possible_votes: 1,
      whip_guess: "unknown"
    )
    text_body = <<~TEXT
      --- DIVISION TITLE ---

      Prohibition of Human Cloning for Reproduction and the Regulation of Human Embryo Research Amendment Bill 2006 - Consideration in Detail

      --- MOTION EFFECT ---

      This is some test text. I'd like to illustrate formatting like *italics* and the following points:

      * My first point is simple
      * But I do have other points to
      * And sometimes I do go on

      To back up my arguments I ensure that I link to official sources like the [APH Official website](http://aph.gov.au).
      --- COMMENTS AND NOTES ---

      (put thoughts and notes for other researchers here)
    TEXT
    create(
      :wiki_motion,
      id: 2,
      division_id: division.id,
      text_body: text_body,
      user_id: user.id,
      created_at: "2014-05-15 08:44:37"
    )
    create(
      :vote,
      division_id: division.id,
      member_id: member_tony_abbott.id,
      vote: "aye",
      teller: false
    )
    create(
      :vote,
      division_id: division.id,
      member_id: member_kevin_rudd.id,
      vote: "aye",
      teller: false
    )
    create(
      :vote,
      division_id: division.id,
      member_id: member_roger_price.id,
      vote: "aye",
      teller: true
    )
    division
  end

  let(:division_senate_2009_11_25_8) do
    division = create(
      :division,
      id: 2037,
      date: "2009-11-25",
      clock_time: "016:13:00",
      number: 8,
      house: "senate",
      name: "Carbon Pollution Reduction Scheme Legislation",
      source_url: "http://parlinfo.aph.gov.au/parlInfo/search/display/display.w3p;query=Id:chamber/hansards/2009-11-25/0000",
      debate_url: "http://parlinfo.aph.gov.au/parlInfo/search/display/display.w3p;query=Id:chamber/hansards/2009-11-25/0000",
      motion: '<p pwmotiontext="moved">That the question for the third reading of the Carbon Pollution Reduction Scheme Bill&#160;2009&#160;[No. 2] and 10 related bills not be put until the third sitting day in February 2010.</p>',
      debate_gid: "uk.org.publicwhip/lords/2009-11-25.76.2"
    )
    create(
      :division_info,
      division_id: division.id,
      rebellions: 11,
      tells: 2,
      turnout: 65,
      possible_turnout: 76,
      aye_majority: -31
    )
    create(
      :whip,
      division_id: division.id,
      party: "Australian Greens",
      aye_votes: 0,
      aye_tells: 0,
      no_votes: 5,
      no_tells: 0,
      both_votes: 0,
      abstention_votes: 0,
      possible_votes: 5,
      whip_guess: "no"
    )
    create(
      :whip,
      division_id: division.id,
      party: "Australian Labor Party",
      aye_votes: 0,
      aye_tells: 0,
      no_votes: 28,
      no_tells: 1,
      both_votes: 0,
      abstention_votes: 0,
      possible_votes: 31,
      whip_guess: "no"
    )
    create(
      :whip,
      division_id: division.id,
      party: "Country Liberal Party",
      aye_votes: 0,
      aye_tells: 0,
      no_votes: 0,
      no_tells: 0,
      both_votes: 0,
      abstention_votes: 0,
      possible_votes: 1,
      whip_guess: "unknown"
    )
    create(
      :whip,
      division_id: division.id,
      party: "DPRES",
      aye_votes: 1,
      aye_tells: 0,
      no_votes: 0,
      no_tells: 0,
      both_votes: 0,
      abstention_votes: 0,
      possible_votes: 1,
      whip_guess: "aye"
    )
    create(
      :whip,
      division_id: division.id,
      party: "Family First Party",
      aye_votes: 1,
      aye_tells: 0,
      no_votes: 0,
      no_tells: 0,
      both_votes: 0,
      abstention_votes: 0,
      possible_votes: 1,
      whip_guess: "aye"
    )
    create(
      :whip,
      division_id: division.id,
      party: "Independent",
      aye_votes: 0,
      aye_tells: 0,
      no_votes: 1,
      no_tells: 0,
      both_votes: 0,
      abstention_votes: 0,
      possible_votes: 1,
      whip_guess: "none"
    )
    create(
      :whip,
      division_id: division.id,
      party: "Liberal Party",
      aye_votes: 11,
      aye_tells: 0,
      no_votes: 12,
      no_tells: 0,
      both_votes: 0,
      abstention_votes: 0,
      possible_votes: 30,
      whip_guess: "no"
    )
    create(
      :whip,
      division_id: division.id,
      party: "National Party",
      aye_votes: 3,
      aye_tells: 1,
      no_votes: 0,
      no_tells: 0,
      both_votes: 0,
      abstention_votes: 0,
      possible_votes: 5,
      whip_guess: "aye"
    )
    create(
      :whip,
      division_id: division.id,
      party: "PRES",
      aye_votes: 0,
      aye_tells: 0,
      no_votes: 1,
      no_tells: 0,
      both_votes: 0,
      abstention_votes: 0,
      possible_votes: 1,
      whip_guess: "no"
    )
    create(
      :vote,
      division_id: division.id,
      member_id: member_christine_milne.id,
      vote: "no",
      teller: false
    )
    create(
      :vote,
      division_id: division.id,
      member_id: member_christopher_back.id,
      vote: "aye",
      teller: false
    )
    create(
      :vote,
      division_id: division.id,
      member_id: member_judith_adams.id,
      vote: "aye",
      teller: true
    )
    create(
      :vote,
      division_id: division.id,
      member_id: member_disagreeable_curmudgeon.id,
      vote: "no",
      teller: false
    )
    create(
      :vote,
      division_id: division.id,
      member_id: member_surly_nihilist.id,
      vote: "aye",
      teller: false
    )
    division
  end

  let(:division_senate_2009_11_30_8) do
    division = create(
      :division,
      id: 59,
      date: "2009-11-30",
      clock_time: "012:00:00",
      number: 8,
      house: "senate",
      name: "Carbon Pollution Reduction Scheme (Cprs Fuel Credits) Bill 2009 [No. 2]; Carbon Pollution Reduction Scheme Amendment (Household Assistance) Bill 2009 [No. 2] &#8212; Third Reading",
      source_url: "http://parlinfo.aph.gov.au/parlInfo/search/display/display.w3p;query=Id:chamber/hansards/2009-11-30/0000",
      debate_url: "http://parlinfo.aph.gov.au/parlInfo/search/display/display.w3p;query=Id:chamber/hansards/2009-11-30/0000",
      motion: '<p pwmotiontext="moved">That these bills be now read a third time.</p>',
      debate_gid: "uk.org.publicwhip/lords/2009-11-30.559.1"
    )
    create(
      :division_info,
      division_id: division.id,
      rebellions: 1,
      tells: 2,
      turnout: 73,
      possible_turnout: 76,
      aye_majority: -9
    )
    create(
      :whip,
      division_id: division.id,
      party: "Australian Greens",
      aye_votes: 0,
      aye_tells: 0,
      no_votes: 5,
      no_tells: 0,
      both_votes: 0,
      abstention_votes: 0,
      possible_votes: 5,
      whip_guess: "no"
    )
    create(
      :whip,
      division_id: division.id,
      party: "Liberal Party",
      aye_votes: 1,
      aye_tells: 0,
      no_votes: 27,
      no_tells: 1,
      both_votes: 0,
      abstention_votes: 0,
      possible_votes: 30,
      whip_guess: "no"
    )
    create(
      :vote,
      division_id: division.id,
      member_id: member_christine_milne.id,
      vote: "no",
      teller: false
    )
    create(
      :vote,
      division_id: division.id,
      member_id: member_christopher_back.id,
      vote: "no",
      teller: false
    )
    division
  end

  # This one used for checking the ordering of divisions by date.
  # Chronologically it is later than division_id 59, but the sql returns it
  # before that division when no orderby clause is used.
  # Unfortunately that behaviour is arbitrary, and changing the test fixtures or
  # the environment will likely change that order. One Solution would be to
  # mock out the sql calls.
  let(:division_senate_2009_12_30_8) do
    division = create(
      :division,
      id: 4444,
      date: "2009-12-30",
      clock_time: "012:00:00",
      number: 8,
      house: "senate",
      name: "Proceedural ban of flatulence during divisions",
      source_url: "https://www.youtube.com/watch?v=yUGw_l3G-JE",
      debate_url: "https://www.youtube.com/watch?v=yUGw_l3G-JE",
      motion: '<p pwmotiontext="moved">That the member for Grayndler stop using biological means to influence the outcome of divisions.</p>',
      debate_gid: "uk.org.publicwhip/lords/2009-11-10.559.1"
    )
    create(
      :division_info,
      division_id: division.id,
      rebellions: 0,
      tells: 2,
      turnout: 73,
      possible_turnout: 76,
      aye_majority: -9
    )
    create(
      :whip,
      division_id: division.id,
      party: "Australian Greens",
      aye_votes: 5,
      aye_tells: 0,
      no_votes: 0,
      no_tells: 0,
      both_votes: 0,
      abstention_votes: 0,
      possible_votes: 5,
      whip_guess: "aye"
    )
    create(
      :whip,
      division_id: division.id,
      party: "Liberal Party",
      aye_votes: 1,
      aye_tells: 0,
      no_votes: 27,
      no_tells: 1,
      both_votes: 0,
      abstention_votes: 0,
      possible_votes: 30,
      whip_guess: "no"
    )
    create(
      :vote,
      division_id: division.id,
      member_id: member_christine_milne.id,
      vote: "aye",
      teller: false
    )
    create(
      :vote,
      division_id: division.id,
      member_id: member_christopher_back.id,
      vote: "no",
      teller: false
    )
    division
  end

  let(:policy1) do
    policy = create(
      :policy,
      id: 1,
      name: "marriage equality",
      user_id: user.id,
      description: "access to marriage should be equal",
      private: 0,
      created_at: 1.day.ago,
      updated_at: 1.day.ago
    )
    create(
      :policy_division,
      division_id: division_representatives_2013_3_14_1.id,
      policy_id: policy.id,
      vote: "aye"
    )
    policy
  end

  let(:policy2) do
    policy = create(
      :policy,
      id: 2,
      name: "offshore processing",
      user_id: user.id,
      description: "refugees arrving by boat should be processed offshore",
      private: 0,
      created_at: 1.day.ago,
      updated_at: 1.day.ago
    )
    create(
      :policy_division,
      division_id: division_senate_2013_3_14_1.id,
      policy_id: policy.id,
      vote: "no3"
    )
    create(
      :policy_division,
      division_id: division_representatives_2006_12_06_3.id,
      policy_id: policy.id,
      vote: "no"
    )
    policy
  end

  let(:policy3) do
    policy = create(
      :policy,
      id: 3,
      name: "provisional policies",
      user_id: user.id,
      description: "A provisional policy",
      private: 2,
      created_at: 1.day.ago,
      updated_at: 1.day.ago
    )
    create(
      :policy_division,
      division_id: division_senate_2013_3_14_1.id,
      policy_id: policy.id,
      vote: "no3"
    )
    policy
  end

  let(:user) do
    create(
      :user,
      id: 1,
      name: "Henare Degan",
      email: "henare@oaf.org.au",
      confirmed_at: "2013-10-20 10:10:53"
    )
  end

  let(:person_tony_abbott) do
    create(
      :person,
      small_image_url: "https://www.openaustralia.org.au/images/mps/10001.jpg",
      large_image_url: "https://www.openaustralia.org.au/images/mpsL/10001.jpg",
      id: 10001
    )
  end

  let(:person_kevin_rudd) do
    create(
      :person,
      small_image_url: "https://www.openaustralia.org.au/images/mps/10552.jpg",
      large_image_url: "https://www.openaustralia.org.au/images/mpsL/10552.jpg",
      id: 10552
    )
  end

  let(:person_christine_milne) do
    create(
      :person,
      small_image_url: "https://www.openaustralia.org.au/images/mps/10458.jpg",
      large_image_url: "https://www.openaustralia.org.au/images/mpsL/10458.jpg",
      id: 10458
    )
  end

  let(:person_john_howard) do
    create(
      :person,
      small_image_url: "https://www.openaustralia.org.au/images/mps/10313.jpg",
      large_image_url: "https://www.openaustralia.org.au/images/mpsL/10313.jpg",
      id: 10313
    )
  end

  let(:person_maxine_mckew) do
    create(
      :person,
      small_image_url: "https://www.openaustralia.org.au/images/mps/10439.jpg",
      large_image_url: "https://www.openaustralia.org.au/images/mpsL/10439.jpg",
      id: 10439
    )
  end

  let(:person_john_alexander) do
    create(
      :person,
      small_image_url: "https://www.openaustralia.org.au/images/mps/10725.jpg",
      large_image_url: "https://www.openaustralia.org.au/images/mpsL/10725.jpg",
      id: 10725
    )
  end

  let(:person_christopher_back) do
    create(
      :person,
      small_image_url: "https://www.openaustralia.org.au/images/mps/10722.jpg",
      large_image_url: "https://www.openaustralia.org.au/images/mpsL/10722.jpg",
      id: 10722
    )
  end

  let(:person_judith_adams) do
    create(
      :person,
      small_image_url: "https://www.openaustralia.org.au/images/mps/10005.jpg",
      large_image_url: "https://www.openaustralia.org.au/images/mpsL/10005.jpg",
      id: 10005
    )
  end

  let(:person_paul_zammit) do
    create(
      :person,
      small_image_url: "https://www.openaustralia.org.au/images/mps/10694.jpg",
      large_image_url: "https://www.openaustralia.org.au/images/mpsL/10694.jpg",
      id: 10694
    )
  end

  let(:person_disagreeable_curmudgeon) do
    create(
      :person,
      small_image_url: "https://www.openaustralia.org.au/images/mps/22221.jpg",
      large_image_url: "https://www.openaustralia.org.au/images/mpsL/22221.jpg",
      id: 22221
    )
  end

  let(:person_surly_nihilist) do
    create(
      :person,
      small_image_url: "https://www.openaustralia.org.au/images/mps/33331.jpg",
      large_image_url: "https://www.openaustralia.org.au/images/mpsL/33331.jpg",
      id: 33331
    )
  end

  let(:person_roger_price) do
    create(
      :person,
      small_image_url: "https://www.openaustralia.org.au/images/mps/10519.jpg",
      large_image_url: "https://www.openaustralia.org.au/images/mpsL/10519.jpg",
      id: 10519
    )
  end

  let(:member_tony_abbott) do
    create(
      :member,
      id: 1,
      gid: "uk.org.publicwhip/member/1",
      source_gid: "",
      first_name: "Tony",
      last_name: "Abbott",
      title: "",
      constituency: "Warringah",
      party: "Liberal Party",
      house: "representatives",
      entered_house: "1994-03-26",
      left_house: "9999-12-31",
      entered_reason: "by_election",
      left_reason: "still_in_office",
      person_id: person_tony_abbott.id
    )
  end

  let(:member_kevin_rudd) do
    create(
      :member,
      id: 450,
      gid: "uk.org.publicwhip/member/450",
      source_gid: "",
      first_name: "Kevin",
      last_name: "Rudd",
      title: "",
      constituency: "Griffith",
      party: "Australian Labor Party",
      house: "representatives",
      entered_house: "1998-10-03",
      left_house: "2013-11-22",
      entered_reason: "general_election",
      left_reason: "resigned",
      person_id: person_kevin_rudd.id
    )
  end

  let(:member_christine_milne) do
    create(
      :member,
      id: 100156,
      gid: "uk.org.publicwhip/lord/100156",
      source_gid: "",
      first_name: "Christine",
      last_name: "Milne",
      title: "",
      constituency: "Tasmania",
      party: "Australian Greens",
      house: "senate",
      entered_house: "2005-07-01",
      left_house: "9999-12-31",
      entered_reason: "general_election",
      left_reason: "still_in_office",
      person_id: person_christine_milne.id
    )
  end

  let(:member_john_howard) do
    create(
      :member,
      id: 265,
      first_name: "John",
      last_name: "Howard",
      party: "Liberal Party",
      constituency: "Bennelong",
      house: "representatives",
      gid: "uk.org.publicwhip/member/265",
      source_gid: "",
      title: "",
      entered_house: "1974-05-18",
      left_house: "2007-11-24",
      entered_reason: "general_election",
      left_reason: "",
      person_id: person_john_howard.id
    )
  end

  let(:member_maxine_mckew) do
    create(
      :member,
      id: 367,
      first_name: "Maxine",
      last_name: "McKew",
      party: "Australian Labor Party",
      constituency: "Bennelong",
      house: "representatives",
      gid: "uk.org.publicwhip/member/367",
      source_gid: "",
      title: "",
      entered_house: "2007-11-24",
      left_house: "2010-08-21",
      entered_reason: "general_election",
      left_reason: "",
      person_id: person_maxine_mckew.id
    )
  end

  let(:member_john_alexander) do
    create(
      :member,
      id: 589,
      first_name: "John",
      last_name: "Alexander",
      party: "Liberal Party",
      constituency: "Bennelong",
      house: "representatives",
      gid: "uk.org.publicwhip/member/589",
      source_gid: "",
      title: "",
      entered_house: "2010-08-21",
      left_house: "9999-12-31",
      entered_reason: "general_election",
      left_reason: "still_in_office",
      person_id: person_john_alexander.id
    )
  end

  let(:member_christopher_back) do
    create(
      :member,
      id: 100279,
      gid: "uk.org.publicwhip/lord/100279",
      source_gid: "",
      first_name: "Christopher",
      last_name: "Back",
      title: "",
      constituency: "WA",
      party: "Liberal Party",
      house: "senate",
      entered_house: "2009-03-11",
      left_house: "9999-12-31",
      entered_reason: "general_election",
      left_reason: "still_in_office",
      person_id: person_christopher_back.id
    )
  end

  let(:member_judith_adams) do
    create(
      :member,
      id: 100002,
      gid: "uk.org.publicwhip/lord/100002",
      source_gid: "",
      first_name: "Judith",
      last_name: "Adams",
      title: "",
      constituency: "WA",
      party: "Liberal Party",
      house: "senate",
      entered_house: "2005-07-01",
      left_house: "2012-03-31",
      entered_reason: "general_election",
      left_reason: "died",
      person_id: person_judith_adams.id
    )
  end

  let(:member_paul_zammit) do
    create(
      :member,
      id: 562,
      gid: "uk.org.publicwhip/member/562",
      source_gid: "",
      first_name: "Paul",
      last_name: "Zammit",
      title: "",
      constituency: "Lowe",
      party: "Independent",
      house: "representatives",
      entered_house: "1996-03-02",
      left_house: "1998-10-03",
      entered_reason: "general_election",
      left_reason: "",
      person_id: person_paul_zammit.id
    )
  end

  let(:member_disagreeable_curmudgeon) do
    create(
      :member,
      id: 222222,
      gid: "uk.org.publicwhip/member/222222",
      source_gid: "",
      first_name: "Disagreeable",
      last_name: "Curmudgeon",
      title: "",
      constituency: "WA",
      party: "Independent",
      house: "senate",
      entered_house: "1996-03-02",
      left_house: "2010-10-03",
      entered_reason: "general_election",
      left_reason: "",
      person_id: person_disagreeable_curmudgeon.id
    )
  end

  let(:member_surly_nihilist) do
    create(
      :member,
      id: 333333,
      gid: "uk.org.publicwhip/member/333333",
      source_gid: "",
      first_name: "Surly",
      last_name: "Nihilist",
      title: "",
      constituency: "WA",
      party: "Independent",
      house: "senate",
      entered_house: "1996-03-02",
      left_house: "2010-10-03",
      entered_reason: "general_election",
      left_reason: "",
      person_id: person_surly_nihilist.id
    )
  end

  let(:member_roger_price) do
    create(
      :member,
      id: 424,
      gid: "uk.org.publicwhip/member/424",
      source_gid: "",
      first_name: "Roger",
      last_name: "Price",
      title: "",
      constituency: "Chifley",
      party: "Australian Labor Party",
      house: "representatives",
      entered_house: "1984-12-01",
      left_house: "2010-08-21",
      entered_reason: "general_election",
      left_reason: "",
      person_id: person_roger_price.id
    )
  end

  def member_infos_fixtures
    create(
      :member_info,
      member_id: member_tony_abbott.id,
      rebellions: 0,
      tells: 0,
      votes_attended: 1,
      votes_possible: 2,
      aye_majority: 1
    )

    create(
      :member_info,
      member_id: member_kevin_rudd.id,
      rebellions: 0,
      tells: 0,
      votes_attended: 2,
      votes_possible: 2,
      aye_majority: 0
    )

    create(
      :member_info,
      member_id: member_christine_milne.id,
      rebellions: 0,
      tells: 0,
      votes_attended: 4,
      votes_possible: 4,
      aye_majority: -2
    )

    create(
      :member_info,
      member_id: member_john_howard.id,
      rebellions: 0,
      tells: 0,
      votes_attended: 0,
      votes_possible: 1,
      aye_majority: 0
    )

    create(
      :member_info,
      member_id: member_john_alexander.id,
      rebellions: 0,
      tells: 0,
      votes_attended: 0,
      votes_possible: 1,
      aye_majority: 0
    )

    create(
      :member_info,
      member_id: member_christopher_back.id,
      rebellions: 0,
      tells: 0,
      votes_attended: 3,
      votes_possible: 4,
      aye_majority: -1
    )

    create(
      :member_info,
      member_id: member_judith_adams.id,
      rebellions: 0,
      tells: 1,
      votes_attended: 1,
      votes_possible: 3,
      aye_majority: 1
    )

    create(
      :member_info,
      member_id: member_roger_price.id,
      rebellions: 0,
      tells: 1,
      votes_attended: 1,
      votes_possible: 1,
      aye_majority: 1
    )

    create(
      :member_info,
      member_id: member_disagreeable_curmudgeon.id,
      rebellions: 0,
      tells: 0,
      votes_attended: 1,
      votes_possible: 3,
      aye_majority: -1
    )

    create(
      :member_info,
      member_id: member_surly_nihilist.id,
      rebellions: 0,
      tells: 0,
      votes_attended: 1,
      votes_possible: 3,
      aye_majority: 1
    )
  end

  def member_distances_fixtures
    create(
      :member_distance,
      member1_id: member_tony_abbott.id,
      member2_id: member_tony_abbott.id,
      nvotessame: 1,
      nvotesdiffer: 0,
      nvotesabsent: 0,
      distance_a: 0.0,
      distance_b: 0.0
    )

    create(
      :member_distance,
      member1_id: member_tony_abbott.id,
      member2_id: member_john_howard.id,
      nvotessame: 0,
      nvotesdiffer: 0,
      nvotesabsent: 0,
      distance_a: -1.0,
      distance_b: -1.0
    )

    create(
      :member_distance,
      member1_id: member_tony_abbott.id,
      member2_id: member_maxine_mckew.id,
      nvotessame: 0,
      nvotesdiffer: 0,
      nvotesabsent: 0,
      distance_a: -1.0,
      distance_b: -1.0
    )

    create(
      :member_distance,
      member1_id: member_tony_abbott.id,
      member2_id: member_kevin_rudd.id,
      nvotessame: 1,
      nvotesdiffer: 0,
      nvotesabsent: 2,
      distance_a: 0.142857,
      distance_b: 0.0
    )

    create(
      :member_distance,
      member1_id: member_tony_abbott.id,
      member2_id: member_john_alexander.id,
      nvotessame: 0,
      nvotesdiffer: 0,
      nvotesabsent: 0,
      distance_a: -1.0,
      distance_b: -1.0
    )

    create(
      :member_distance,
      member1_id: member_john_howard.id,
      member2_id: member_john_howard.id,
      nvotessame: 0,
      nvotesdiffer: 0,
      nvotesabsent: 0,
      distance_a: -1.0,
      distance_b: -1.0
    )

    create(
      :member_distance,
      member1_id: member_john_howard.id,
      member2_id: member_kevin_rudd.id,
      nvotessame: 0,
      nvotesdiffer: 0,
      nvotesabsent: 2,
      distance_a: 0.5,
      distance_b: -1.0
    )

    create(
      :member_distance,
      member1_id: member_maxine_mckew.id,
      member2_id: member_maxine_mckew.id,
      nvotessame: 0,
      nvotesdiffer: 0,
      nvotesabsent: 0,
      distance_a: -1.0,
      distance_b: -1.0
    )

    create(
      :member_distance,
      member1_id: member_maxine_mckew.id,
      member2_id: member_kevin_rudd.id,
      nvotessame: 0,
      nvotesdiffer: 0,
      nvotesabsent: 0,
      distance_a: -1.0,
      distance_b: -1.0
    )

    create(
      :member_distance,
      member1_id: member_kevin_rudd.id,
      member2_id: member_kevin_rudd.id,
      nvotessame: 2,
      nvotesdiffer: 0,
      nvotesabsent: 0,
      distance_a: 0.0,
      distance_b: 0.0
    )

    create(
      :member_distance,
      member1_id: member_kevin_rudd.id,
      member2_id: member_john_alexander.id,
      nvotessame: 0,
      nvotesdiffer: 0,
      nvotesabsent: 0,
      distance_a: -1.0,
      distance_b: -1.0
    )

    create(
      :member_distance,
      member1_id: member_john_alexander.id,
      member2_id: member_john_alexander.id,
      nvotessame: 0,
      nvotesdiffer: 0,
      nvotesabsent: 0,
      distance_a: -1.0,
      distance_b: -1.0
    )

    create(
      :member_distance,
      member1_id: member_christine_milne.id,
      member2_id: member_christine_milne.id,
      nvotessame: 2,
      nvotesdiffer: 0,
      nvotesabsent: 0,
      distance_a: 0.0,
      distance_b: 0.0
    )

    create(
      :member_distance,
      member1_id: member_christine_milne.id,
      member2_id: member_christopher_back.id,
      nvotessame: 0,
      nvotesdiffer: 1,
      nvotesabsent: 0,
      distance_a: 1.0,
      distance_b: 1.0
    )

    create(
      :member_distance,
      member1_id: member_christopher_back.id,
      member2_id: member_christopher_back.id,
      nvotessame: 1,
      nvotesdiffer: 0,
      nvotesabsent: 0,
      distance_a: 0.0,
      distance_b: 0.0
    )
  end

  def policy_person_distances_fixtures
    create(
      :policy_person_distance,
      policy_id: policy1.id,
      person_id: person_tony_abbott.id,
      nvotessame: 0,
      nvotessamestrong: 0,
      nvotesdiffer: 0,
      nvotesdifferstrong: 0,
      nvotesabsent: 1,
      nvotesabsentstrong: 0,
      distance_a: 0.5
    )

    create(
      :policy_person_distance,
      policy_id: policy1.id,
      person_id: person_kevin_rudd.id,
      nvotessame: 0,
      nvotessamestrong: 0,
      nvotesdiffer: 1,
      nvotesdifferstrong: 0,
      nvotesabsent: 0,
      nvotesabsentstrong: 0,
      distance_a: 1.0
    )

    create(
      :policy_person_distance,
      policy_id: policy1.id,
      person_id: person_john_alexander.id,
      nvotessame: 0,
      nvotessamestrong: 0,
      nvotesdiffer: 0,
      nvotesdifferstrong: 0,
      nvotesabsent: 1,
      nvotesabsentstrong: 0,
      distance_a: 0.5
    )
  end

  def offices_fixtures
    create(
      :office,
      id: 504,
      position: "Minister for Health and Ageing",
      from_date: "2003-10-7",
      to_date: "2007-12-3",
      person_id: person_tony_abbott.id,
      dept: "",
      responsibility: ""
    )

    create(
      :office,
      id: 1201,
      position: "Shadow Minister for Families, Community Services, Indigenous Affairs and the Voluntary Sector",
      from_date: "2007-12-6",
      to_date: "2008-9-22",
      person_id: person_tony_abbott.id,
      dept: "",
      responsibility: ""
    )

    create(
      :office,
      id: 1202,
      position: "Shadow Minister for Families, Housing, Community Services and Indigenous Affairs",
      from_date: "2008-9-22",
      to_date: "2009-12-8",
      person_id: person_tony_abbott.id,
      dept: "",
      responsibility: ""
    )

    create(
      :office,
      id: 1200,
      position: "Leader of the Opposition",
      from_date: "2009-12-8",
      to_date: "9999-12-31",
      person_id: person_tony_abbott.id,
      dept: "",
      responsibility: ""
    )

    create(
      :office,
      id: 380,
      position: "Prime Minister",
      from_date: "2013-6-27",
      to_date: "9999-12-31",
      person_id: person_kevin_rudd.id,
      dept: "",
      responsibility: ""
    )
  end
end
