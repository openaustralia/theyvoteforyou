Dir[Rails.root.join('spec/support/static_regression_test_data/*.rb')].each { |f| require f }

module StaticRegressionTestDataHelpers
  def create_data_for_static_regression_tests
    create_offices_for_regression_tests
    create_users_for_regression_tests
    create_people_for_regression_tests
    create_members_for_regression_tests
    create_member_infos_for_regression_tests
    create_policies_for_regression_tests
    create_divisions_for_regression_tests
    create_policy_divisions_for_regression_tests
    # We want to feed specific PolicyPersonDistance records here,
    # so we need to clear out the ones generated when the PolicyDivisions
    # are created/the callback is triggered.
    PolicyPersonDistance.delete_all
    create_policy_person_distances_for_regression_tests
    create_whips_for_regression_tests
    create_votes_for_regression_tests
    create_wiki_motions_for_regression_tests
  end
end
