module StaticRegressionTestDataHelpers
  def create_members
    create(
      :member,
      id: 1,
      gid: "uk.org.publicwhip/member/1",
      source_gid: '',
      first_name: "Tony",
      last_name: "Abbott",
      title: '',
      constituency: "Warringah",
      party: "Liberal Party",
      house: "representatives",
      entered_house: "1994-03-26",
      left_house: "9999-12-31",
      entered_reason: "by_election",
      left_reason: "still_in_office",
      person_id: 10001
    )

    create(
      :member,
      id: 450,
      gid: 'uk.org.publicwhip/member/450',
      source_gid: '',
      first_name: 'Kevin',
      last_name: 'Rudd',
      title: '',
      constituency: 'Griffith',
      party: "Australian Labor Party",
      house: 'representatives',
      entered_house: '1998-10-03',
      left_house: '2013-11-22',
      entered_reason: 'general_election',
      left_reason: 'resigned',
      person_id: 10552
    )

    create(
      :member,
      id: 100156,
      gid: "uk.org.publicwhip/lord/100156",
      source_gid: '',
      first_name: "Christine",
      last_name: "Milne",
      title: '',
      constituency: "Tasmania",
      party: "Australian Greens",
      house: "senate",
      entered_house: "2005-07-01",
      left_house: "9999-12-31",
      entered_reason: "general_election",
      left_reason: "still_in_office",
      person_id: 10458
    )

    create(
      :member,
      id: 265,
      first_name: 'John',
      last_name: 'Howard',
      party: 'Liberal Party',
      constituency: 'Bennelong',
      house: "representatives",
      gid: 'uk.org.publicwhip/member/265',
      source_gid: "",
      title: "",
      entered_house: '1974-05-18',
      left_house: '2007-11-24',
      entered_reason: 'general_election',
      left_reason: '',
      person_id: 10313
    )

    create(
      :member,
      id: 367,
      first_name: 'Maxine',
      last_name: 'McKew',
      party: 'Australian Labor Party',
      constituency: 'Bennelong',
      house: "representatives",
      gid: 'uk.org.publicwhip/member/367',
      source_gid: "",
      title: "",
      entered_house: "2007-11-24",
      left_house: "2010-08-21",
      entered_reason: 'general_election',
      left_reason: '',
      person_id: 10439
    )

    create(
      :member,
      id: 589,
      first_name: 'John',
      last_name: 'Alexander',
      party: 'Liberal Party',
      constituency: 'Bennelong',
      house: "representatives",
      gid: 'uk.org.publicwhip/member/589',
      source_gid: "",
      title: "",
      entered_house: "2010-08-21",
      left_house: "9999-12-31",
      entered_reason: 'general_election',
      left_reason: 'still_in_office',
      person_id: 10725
    )

    create(
      :member,
      id: 100279,
      gid: "uk.org.publicwhip/lord/100279",
      source_gid: '',
      first_name: "Christopher",
      last_name: "Back",
      title: '',
      constituency: "WA",
      party: "Liberal Party",
      house: "senate",
      entered_house: "2009-03-11",
      left_house: "9999-12-31",
      entered_reason: "general_election",
      left_reason: "still_in_office",
      person_id: 10722
    )

    create(
      :member,
      id: 100002,
      gid: "uk.org.publicwhip/lord/100002",
      source_gid: '',
      first_name: "Judith",
      last_name: "Adams",
      title: '',
      constituency: "WA",
      party: "Liberal Party",
      house: "senate",
      entered_house: "2005-07-01",
      left_house: "2012-03-31",
      entered_reason: "general_election",
      left_reason: "died",
      person_id: 10005
    )

    create(
      :member,
      id: 562,
      gid: "uk.org.publicwhip/member/562",
      source_gid: '',
      first_name: "Paul",
      last_name: "Zammit",
      title: '',
      constituency: "Lowe",
      party: "Independent",
      house: "representatives",
      entered_house: "1996-03-02",
      left_house: "1998-10-03",
      entered_reason: "general_election",
      left_reason: '',
      person_id: 10694
    )

    create(
      :member,
      id: 222222,
      gid: "uk.org.publicwhip/member/222222",
      source_gid: '',
      first_name: "Disagreeable",
      last_name: "Curmudgeon",
      title: '',
      constituency: "WA",
      party: "Independent",
      house: "senate",
      entered_house: "1996-03-02",
      left_house: "2010-10-03",
      entered_reason: "general_election",
      left_reason: '',
      person_id: 22221
    )

    create(
      :member,
      id: 333333,
      gid: "uk.org.publicwhip/member/333333",
      source_gid: '',
      first_name: "Surly",
      last_name: "Nihilist",
      title: '',
      constituency: "WA",
      party: "Independent",
      house: "senate",
      entered_house: "1996-03-02",
      left_house: "2010-10-03",
      entered_reason: "general_election",
      left_reason: '',
      person_id: 33331
    )

    create(
      :member,
      id: 424,
      gid: "uk.org.publicwhip/member/424",
      source_gid: '',
      first_name: "roger",
      last_name: "price",
      title: '',
      constituency: "chifley",
      party: "australian labor party",
      house: "representatives",
      entered_house: "1984-12-01",
      left_house: "2010-08-21",
      entered_reason: "general_election",
      left_reason: '',
      person_id: 10519
    )
  end
end
