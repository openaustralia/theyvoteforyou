module StaticRegressionTestDataHelpers
  def create_member_distances
    create(
      :member_distance,
      member1_id: 1,
      member2_id: 1,
      nvotessame: 1,
      nvotesdiffer: 0,
      nvotesabsent: 0,
      distance_a: 0.0,
      distance_b: 0.0
    )

    create(
      :member_distance,
      member1_id: 1,
      member2_id: 265,
      nvotessame: 0,
      nvotesdiffer: 0,
      nvotesabsent: 0,
      distance_a: -1.0,
      distance_b: -1.0
    )

    create(
      :member_distance,
      member1_id: 1,
      member2_id: 367,
      nvotessame: 0,
      nvotesdiffer: 0,
      nvotesabsent: 0,
      distance_a: -1.0,
      distance_b: -1.0
    )

    create(
      :member_distance,
      member1_id: 1,
      member2_id: 450,
      nvotessame: 1,
      nvotesdiffer: 0,
      nvotesabsent: 2,
      distance_a: 0.142857,
      distance_b: 0.0
    )

    create(
      :member_distance,
      member1_id: 1,
      member2_id: 589,
      nvotessame: 0,
      nvotesdiffer: 0,
      nvotesabsent: 0,
      distance_a: -1.0,
      distance_b: -1.0
    )

    create(
      :member_distance,
      member1_id: 265,
      member2_id: 265,
      nvotessame: 0,
      nvotesdiffer: 0,
      nvotesabsent: 0,
      distance_a: -1.0,
      distance_b: -1.0
    )

    create(
      :member_distance,
      member1_id: 265,
      member2_id: 450,
      nvotessame: 0,
      nvotesdiffer: 0,
      nvotesabsent: 2,
      distance_a: 0.5,
      distance_b: -1.0
    )

    create(
      :member_distance,
      member1_id: 367,
      member2_id: 367,
      nvotessame: 0,
      nvotesdiffer: 0,
      nvotesabsent: 0,
      distance_a: -1.0,
      distance_b: -1.0
    )

    create(
      :member_distance,
      member1_id: 367,
      member2_id: 450,
      nvotessame: 0,
      nvotesdiffer: 0,
      nvotesabsent: 0,
      distance_a: -1.0,
      distance_b: -1.0
    )

    create(
      :member_distance,
      member1_id: 450,
      member2_id: 450,
      nvotessame: 2,
      nvotesdiffer: 0,
      nvotesabsent: 0,
      distance_a: 0.0,
      distance_b: 0.0
    )

    create(
      :member_distance,
      member1_id: 450,
      member2_id: 589,
      nvotessame: 0,
      nvotesdiffer: 0,
      nvotesabsent: 0,
      distance_a: -1.0,
      distance_b: -1.0
    )

    create(
      :member_distance,
      member1_id: 589,
      member2_id: 589,
      nvotessame: 0,
      nvotesdiffer: 0,
      nvotesabsent: 0,
      distance_a: -1.0,
      distance_b: -1.0
    )

    create(
      :member_distance,
      member1_id: 100156,
      member2_id: 100156,
      nvotessame: 2,
      nvotesdiffer: 0,
      nvotesabsent: 0,
      distance_a: 0.0,
      distance_b: 0.0
    )

    create(
      :member_distance,
      member1_id: 100156,
      member2_id: 100279,
      nvotessame: 0,
      nvotesdiffer: 1,
      nvotesabsent: 0,
      distance_a: 1.0,
      distance_b: 1.0
    )

    create(
      :member_distance,
      member1_id: 100279,
      member2_id: 100279,
      nvotessame: 1,
      nvotesdiffer: 0,
      nvotesabsent: 0,
      distance_a: 0.0,
      distance_b: 0.0
    )
  end
end

