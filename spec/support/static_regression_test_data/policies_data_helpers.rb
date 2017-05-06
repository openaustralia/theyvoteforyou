module StaticRegressionTestDataHelpers
  def create_policies_for_regression_tests
    create(
      :policy,
      id: 1,
      name: "marriage equality",
      user_id: 1,
      description: "access to marriage should be equal",
      private: 0,
      created_at: 1.day.ago,
      updated_at: 1.day.ago
    )

    create(
      :policy,
      id: 2,
      name: "offshore processing",
      user_id: 1,
      description: "refugees arrving by boat should be processed offshore",
      private: 0,
      created_at: 1.day.ago,
      updated_at: 1.day.ago
    )

    create(
      :policy,
      id: 3,
      name: "provisional policies",
      user_id: 1,
      description: "A provisional policy",
      private: 2,
      created_at: 1.day.ago,
      updated_at: 1.day.ago
    )
  end

  def create_policy_divisions_for_regression_tests
    create(
      :policy_division,
      division_id: 1,
      policy_id: 1,
      vote: "aye"
    )

    create(
      :policy_division,
      division_id: 9,
      policy_id: 2,
      vote: "no3"
    )

    create(
      :policy_division,
      division_id: 347,
      policy_id: 2,
      vote: "no"
    )

    create(
      :policy_division,
      division_id: 9,
      policy_id: 3,
      vote: "no3"
    )
  end
end
