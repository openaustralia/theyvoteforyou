module StaticRegressionTestDataHelpers
  def create_votes_for_regression_tests
    create(
      :vote,
      division_id: 1,
      member_id: 450,
      vote: 'no',
      teller: false
    )

    create(
      :vote,
      division_id: 9,
      member_id: 100156,
      vote: 'no',
      teller: false
    )

    create(
      :vote,
      division_id: 347,
      member_id: 1,
      vote: 'aye',
      teller: false
    )

    create(
      :vote,
      division_id: 347,
      member_id: 450,
      vote: 'aye',
      teller: false
    )

    create(
      :vote,
      division_id: 2037,
      member_id: 100156,
      vote: 'no',
      teller: false
    )

    create(
      :vote,
      division_id: 2037,
      member_id: 100279,
      vote: 'aye',
      teller: false
    )

    create(
      :vote,
      division_id: 2037,
      member_id: 100002,
      vote: 'aye',
      teller: true
    )

    create(
      :vote,
      division_id: 59,
      member_id: 100156,
      vote: 'no',
      teller: false
    )

    create(
      :vote,
      division_id: 59,
      member_id: 100279,
      vote: 'no',
      teller: false
    )

    create(
      :vote,
      division_id: 2037,
      member_id: 222222,
      vote: 'no',
      teller: false
    )

    create(
      :vote,
      division_id: 2037,
      member_id: 333333,
      vote: 'aye',
      teller: false
    )

    create(
      :vote,
      division_id: 4444,
      member_id: 100156,
      vote: 'aye',
      teller: false
    )

    create(
      :vote,
      division_id: 4444,
      member_id: 100279,
      vote: 'no',
      teller: false
    )

    create(
      :vote,
      division_id: 347,
      member_id: 424,
      vote: 'aye',
      teller: true
    )
  end
end
