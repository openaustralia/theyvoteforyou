require 'spec_helper'
# Compare results of rendering pages via rails and via the old php app

describe PoliciesController, type: :request do
  include HTMLCompareHelper

  before(:each) do
    clear_db_of_fixture_data

    create_people
    create_members
    create_member_infos

    create_divisions
    create_whips
    create_votes
    create_wiki_motions

    create_policies
    create_policy_divisions
    # We want to feed specific PolicyPersonDistance records here,
    # so we need to clear out the ones generated when the PolicyDivisions
    # are created/the callback is triggered.
    PolicyPersonDistance.delete_all
    create_policy_person_distances
  end

  after(:each) do
    clear_db_of_fixture_data
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
