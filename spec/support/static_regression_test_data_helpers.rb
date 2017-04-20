Dir[Rails.root.join('spec/support/static_regression_test_data/*.rb')].each { |f| require f }

module StaticRegressionTestDataHelpers
  def create_data_for_static_regression_tests
    create_users
    create_members
    create_divisions
    create_whips
    create_votes
    create_wiki_motions
  end
end
