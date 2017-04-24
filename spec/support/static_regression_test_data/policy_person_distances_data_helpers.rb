module StaticRegressionTestDataHelpers
  def create_policy_person_distances
    create(
      :policy_person_distance,
      id: 3,
      policy_id: 1,
      person_id: 10001,
      nvotessame: 0,
      nvotessamestrong: 0,
      nvotesdiffer: 0,
      nvotesdifferstrong: 0,
      nvotesabsent: 1,
      nvotesabsentstrong: 0,
      distance_a: 0.5,
      distance_b: -1.0
    )

    create(
      :policy_person_distance,
      id: 2,
      policy_id: 1,
      person_id: 10552,
      nvotessame: 0,
      nvotessamestrong: 0,
      nvotesdiffer: 1,
      nvotesdifferstrong: 0,
      nvotesabsent: 0,
      nvotesabsentstrong: 0,
      distance_a: 1.0,
      distance_b: 1.0
    )

    create(
      :policy_person_distance,
      id: 1,
      policy_id: 1,
      person_id: 10725,
      nvotessame: 0,
      nvotessamestrong: 0,
      nvotesdiffer: 0,
      nvotesdifferstrong: 0,
      nvotesabsent: 1,
      nvotesabsentstrong: 0,
      distance_a: 0.5,
      distance_b: -1.0
    )
  end
end
