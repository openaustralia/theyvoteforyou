module StaticRegressionTestDataHelpers
  def create_whips
    create(
      :whip,
      division_id: 1,
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
      division_id: 1,
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

    create(
      :whip,
      division_id: 9,
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
      :whip,
      division_id: 347,
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
      division_id: 347,
      party: "Country Liberal Party",
      aye_votes: 0,
      aye_tells: 0,
      no_votes: 0,
      no_tells: 0,
      both_votes: 0 ,
      abstention_votes: 0,
      possible_votes: 1,
      whip_guess: "unknown"
    )

    create(
      :whip,
      division_id: 347,
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
      division_id: 347,
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
      division_id: 347,
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
      division_id: 347,
      party: "National Party",
      aye_votes: 9,
      aye_tells: 1,
      no_votes: 1,
      no_tells: 0,
      both_votes: 0 ,
      abstention_votes: 0,
      possible_votes: 11,
      whip_guess: "none"
    )

    create(
      :whip,
      division_id: 347,
      party: "SPK",
      aye_votes: 0,
      aye_tells: 0,
      no_votes: 0,
      no_tells: 0,
      both_votes: 0 ,
      abstention_votes: 0,
      possible_votes: 1,
      whip_guess: "unknown"
    )

    create(
      :whip,
      division_id: 2037,
      party: 'Australian Greens',
      aye_votes: 0,
      aye_tells: 0,
      no_votes: 5,
      no_tells: 0,
      both_votes: 0 ,
      abstention_votes: 0,
      possible_votes: 5,
      whip_guess: 'no'
    )

    create(
      :whip,
      division_id: 2037,
      party: 'Australian Labor Party',
      aye_votes: 0,
      aye_tells: 0,
      no_votes: 28,
      no_tells: 1,
      both_votes: 0,
      abstention_votes: 0,
      possible_votes: 31,
      whip_guess: 'no'
    )

    create(
      :whip,
      division_id: 2037,
      party: 'Country Liberal Party',
      aye_votes: 0,
      aye_tells: 0,
      no_votes: 0,
      no_tells: 0,
      both_votes: 0,
      abstention_votes: 0,
      possible_votes: 1,
      whip_guess: 'unknown'
    )

    create(
      :whip,
      division_id: 2037,
      party: 'DPRES',
      aye_votes: 1,
      aye_tells: 0,
      no_votes: 0,
      no_tells: 0,
      both_votes: 0,
      abstention_votes: 0,
      possible_votes: 1,
      whip_guess: 'aye'
    )

    create(
      :whip,
      division_id: 2037,
      party: 'Family First Party',
      aye_votes: 1,
      aye_tells: 0,
      no_votes: 0,
      no_tells: 0,
      both_votes: 0,
      abstention_votes: 0,
      possible_votes: 1,
      whip_guess: 'aye'
    )

    create(
      :whip,
      division_id: 2037,
      party: 'Independent',
      aye_votes: 0,
      aye_tells: 0,
      no_votes: 1,
      no_tells: 0,
      both_votes: 0,
      abstention_votes: 0,
      possible_votes: 1,
      whip_guess: 'none'
    )

    create(
      :whip,
      division_id: 2037,
      party: 'Liberal Party',
      aye_votes: 11,
      aye_tells: 0,
      no_votes: 12,
      no_tells: 0,
      both_votes: 0,
      abstention_votes: 0,
      possible_votes: 30,
      whip_guess: 'no'
    )

    create(
      :whip,
      division_id: 2037,
      party: 'National Party',
      aye_votes: 3,
      aye_tells: 1,
      no_votes: 0,
      no_tells: 0,
      both_votes: 0,
      abstention_votes: 0,
      possible_votes: 5,
      whip_guess: 'aye'
    )

    create(
      :whip,
      division_id: 2037,
      party: 'PRES',
      aye_votes: 0,
      aye_tells: 0,
      no_votes: 1,
      no_tells: 0,
      both_votes: 0,
      abstention_votes: 0,
      possible_votes: 1,
      whip_guess: 'no'
    )

    create(
      :whip,
      division_id: 59,
      party: 'Australian Greens',
      aye_votes: 0,
      aye_tells: 0,
      no_votes: 5,
      no_tells: 0,
      both_votes: 0,
      abstention_votes: 0,
      possible_votes: 5,
      whip_guess: 'no'
    )

    create(
      :whip,
      division_id: 59,
      party: 'Liberal Party',
      aye_votes: 1,
      aye_tells: 0,
      no_votes: 27,
      no_tells: 1,
      both_votes: 0,
      abstention_votes: 0,
      possible_votes: 30,
      whip_guess: 'no'
    )

    create(
      :whip,
      division_id: 4444,
      party: 'Australian Greens',
      aye_votes: 5,
      aye_tells: 0,
      no_votes: 0,
      no_tells: 0,
      both_votes: 0,
      abstention_votes: 0,
      possible_votes: 5,
      whip_guess: 'aye'
    )

    create(
      :whip,
      division_id: 4444,
      party: 'Liberal Party',
      aye_votes: 1,
      aye_tells: 0,
      no_votes: 27,
      no_tells: 1,
      both_votes: 0,
      abstention_votes: 0,
      possible_votes: 30,
      whip_guess: 'no'
    )
  end
end
