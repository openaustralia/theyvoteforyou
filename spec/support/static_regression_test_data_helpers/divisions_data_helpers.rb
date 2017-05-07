module StaticRegressionTestDataHelpers
  def create_divisions_for_regression_tests
    create(
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
      source_gid: "",
      debate_gid: "uk.org.publicwhip/debate/2013-03-14.17.1",
      markdown: false,
      division_info: create(
        :division_info,
        division_id: 1,
        rebellions: 0,
        tells: 0,
        turnout: 136,
        possible_turnout: 150,
        aye_majority: "-1"
      )
    )

    create(
      :division,
      id: 9,
      date: "2013-3-14",
      number: 1,
      house: "senate",
      name: "Motions &#8212; Renewable Energy Certificates",
      source_url: "http://aph.gov.au/somedebate",
      debate_url: "",
      motion: "",
      source_gid: "",
      debate_gid: "uk.org.publicwhip/lords/2013-03-14.22.1",
      markdown: false,
      division_info: create(
        :division_info,
        division_id: 9,
        rebellions: 0,
        tells: 0,
        turnout: 69,
        possible_turnout: 88,
        aye_majority: -3
      )
    )

    create(
      :division,
      id: 347,
      date: "2006-12-06",
      clock_time: "019:29:00",
      number: 3,
      house: "representatives",
      name: 'Prohibition of Human Cloning for Reproduction and the Regulation of Human Embryo Research Amendment Bill 2006 &#8212; Consideration in Detail',
      source_url: "http://parlinfo.aph.gov.au/parlInfo/search/display/display.w3p;query=Id:chamber/hansardr/2006-12-06/0000",
      debate_url: "http://parlinfo.aph.gov.au/parlInfo/search/display/display.w3p;query=Id:chamber/hansardr/2006-12-06/0000",
      motion: '<p pwmotiontext="moved">That the amendments (<b>Mr Michael Ferguson&#8217;s</b>) be agreed to.</p>',
      source_gid: "uk.org.publicwhip/debate/2006-12-06.112.1",
      debate_gid: "uk.org.publicwhip/debate/2006-12-06.98.1",
      markdown: false,
      division_info: create(
        :division_info,
        division_id: 347,
        rebellions: 0,
        tells: 4,
        turnout: 129,
        possible_turnout: 150,
        aye_majority: -23
      )
    )

    create(
      :division,
      id: 2037,
      date: "2009-11-25",
      clock_time: "016:13:00",
      number: 8,
      house: "senate",
      name: 'Carbon Pollution Reduction Scheme Legislation',
      source_url: "http://parlinfo.aph.gov.au/parlInfo/search/display/display.w3p;query=Id:chamber/hansards/2009-11-25/0000",
      debate_url: "http://parlinfo.aph.gov.au/parlInfo/search/display/display.w3p;query=Id:chamber/hansards/2009-11-25/0000",
      motion: '<p pwmotiontext="moved">That the question for the third reading of the Carbon Pollution Reduction Scheme Bill&#160;2009&#160;[No. 2] and 10 related bills not be put until the third sitting day in February 2010.</p>',
      source_gid: "uk.org.publicwhip/lords/2009-11-25.77.1",
      debate_gid: "uk.org.publicwhip/lords/2009-11-25.76.2",
      markdown: false,
      division_info: create(
        :division_info,
        division_id: 2037,
        rebellions: 11,
        tells: 2,
        turnout: 65,
        possible_turnout: 76,
        aye_majority: -31
      )
    )

    create(
      :division,
      id: 59,
      date: "2009-11-30",
      clock_time: "012:00:00",
      number: 8,
      house: "senate",
      name: 'Carbon Pollution Reduction Scheme (Cprs Fuel Credits) Bill 2009 [No. 2]; Carbon Pollution Reduction Scheme Amendment (Household Assistance) Bill 2009 [No. 2] &#8212; Third Reading',
      source_url: "http://parlinfo.aph.gov.au/parlInfo/search/display/display.w3p;query=Id:chamber/hansards/2009-11-30/0000",
      debate_url: "http://parlinfo.aph.gov.au/parlInfo/search/display/display.w3p;query=Id:chamber/hansards/2009-11-30/0000",
      motion: '<p pwmotiontext="moved">That these bills be now read a third time.</p>',
      source_gid: "uk.org.publicwhip/lords/2009-11-30.560.1",
      debate_gid: "uk.org.publicwhip/lords/2009-11-30.559.1",
      markdown: false,
      division_info: create(
        :division_info,
        division_id: 59,
        rebellions: 1,
        tells: 2,
        turnout: 73,
        possible_turnout: 76,
        aye_majority: -9
      )
    )

    # This one used for checking the ordering of divisions by date.
    # Chronologically it is later than division_id 59, but the sql returns it
    # before that division when no orderby clause is used.
    # Unfortunately that behaviour is arbitrary, and changing the test fixtures or
    # the environment will likely change that order. One Solution would be to
    # mock out the sql calls.
    create(
      :division,
      id: 4444,
      date: "2009-12-30",
      clock_time: "012:00:00",
      number: 8,
      house: "senate",
      name: 'Proceedural ban of flatulence during divisions',
      source_url: "https://www.youtube.com/watch?v=yUGw_l3G-JE",
      debate_url: "https://www.youtube.com/watch?v=yUGw_l3G-JE",
      motion: '<p pwmotiontext="moved">That the member for Grayndler stop using biological means to influence the outcome of divisions.</p>',
      source_gid: "uk.org.publicwhip/lords/2009-11-10.560.1",
      debate_gid: "uk.org.publicwhip/lords/2009-11-10.559.1",
      markdown: false,
      division_info: create(
        :division_info,
        division_id: 4444,
        rebellions: 0,
        tells: 2,
        turnout: 73,
        possible_turnout: 76,
        aye_majority: -9
      )
    )
  end
end
