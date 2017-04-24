Dir[Rails.root.join('spec/support/static_regression_test_data/*.rb')].each { |f| require f }

module StaticRegressionTestDataHelpers
  def create_data_for_static_regression_tests
    create_offices
    create_users
    create_people
    create_members
    create_member_infos
    create_policies
    create_divisions
    create_policy_divisions
    # We want to feed specific PolicyPersonDistance records here,
    # so we need to clear out the ones generated when the PolicyDivisions
    # are created/the callback is triggered.
    PolicyPersonDistance.delete_all
    create_policy_person_distances
    create_whips
    create_votes
    create_wiki_motions
  end
end
