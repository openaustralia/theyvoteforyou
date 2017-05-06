require 'spec_helper'
# Compare results of rendering pages via rails and via the old php app

describe PoliciesController, type: :request do
  include HTMLCompareHelper

  before(:each) do
    create_people_for_regression_tests
    create_members_for_regression_tests
    create_member_infos_for_regression_tests

    create_divisions_for_regression_tests
    create_whips_for_regression_tests
    create_votes_for_regression_tests
    create_wiki_motions_for_regression_tests

    create_policies_for_regression_tests
    create_policy_divisions_for_regression_tests
    # We want to feed specific PolicyPersonDistance records here,
    # so we need to clear out the ones generated when the PolicyDivisions
    # are created/the callback is triggered.
    PolicyPersonDistance.delete_all
    create_policy_person_distances_for_regression_tests
  end

  it "#index" do
    compare_static("/policies.php")
  end

  describe "#show" do
    it { compare_static("/policy.php?id=1") }
    it { compare_static("/policy.php?id=1&display=motions") }

    it { compare_static("/policy.php?id=2") }
    it { compare_static("/policy.php?id=2&display=motions") }
  end
end
