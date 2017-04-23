require 'spec_helper'
# Compare results of rendering pages via rails and via the old php app

describe PoliciesController, type: :request do
  include HTMLCompareHelper

  before(:each) do
    clear_db_of_fixture_data
    DatabaseCleaner.start

    create_divisions
    create_policies
    create_policy_divisions
    create_wiki_motions
  end

  after(:each) do
    DatabaseCleaner.clean
  end

  it "#index" do
    compare_static("/policies.php")
  end

  describe "#show" do
    fixtures :all
    it { compare_static("/policy.php?id=1") }
    it { compare_static("/policy.php?id=1&display=motions") }

    it { compare_static("/policy.php?id=2") }
    it { compare_static("/policy.php?id=2&display=motions") }
  end
end
