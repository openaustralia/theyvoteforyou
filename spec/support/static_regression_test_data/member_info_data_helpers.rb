module StaticRegressionTestDataHelpers
  # TODO don't know what aye_majority does yet
  def create_member_infos
    create(
      :member_info,
      member_id: 1,
      rebellions: 0,
      tells: 0,
      votes_attended: 1,
      votes_possible: 2,
      aye_majority: 1
    )

    create(
      :member_info,
      member_id: 450,
      rebellions: 0,
      tells: 0,
      votes_attended: 2,
      votes_possible: 2,
      aye_majority: 0
    )

    create(
      :member_info,
      member_id: 100156,
      rebellions: 0,
      tells: 0,
      votes_attended: 4,
      votes_possible: 4,
      aye_majority: -2
    )

    create(
      :member_info,
      member_id: 265,
      rebellions: 0,
      tells: 0,
      votes_attended: 0,
      votes_possible: 1,
      aye_majority: 0
    )

    create(
      :member_info,
      member_id: 589,
      rebellions: 0,
      tells: 0,
      votes_attended: 0,
      votes_possible: 1,
      aye_majority: 0
    )

    create(
      :member_info,
      member_id: 100279,
      rebellions: 0,
      tells: 0,
      votes_attended: 3,
      votes_possible: 4,
      aye_majority: -1
    )

    create(
      :member_info,
      member_id: 100002,
      rebellions: 0,
      tells: 1,
      votes_attended: 1,
      votes_possible: 3,
      aye_majority: 1
    )

    create(
      :member_info,
      member_id: 424,
      rebellions: 0,
      tells: 1,
      votes_attended: 1,
      votes_possible: 1,
      aye_majority: 1
    )

    create(
      :member_info,
      member_id: 222222,
      rebellions: 0,
      tells: 0,
      votes_attended: 1,
      votes_possible: 3,
      aye_majority: -1
    )

    create(
      :member_info,
      member_id: 333333,
      rebellions: 0,
      tells: 0,
      votes_attended: 1,
      votes_possible: 3,
      aye_majority: 1
    )
  end
end
