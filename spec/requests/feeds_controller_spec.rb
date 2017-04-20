require 'spec_helper'

describe FeedsController, type: :request do
  include HTMLCompareHelper

  describe '#mp-info' do
    fixtures :all

    it { compare_static '/feeds/mp-info.xml' }
    it { compare_static '/feeds/mp-info.xml?house=senate' }
  end

  describe '#mpdream-info' do
    before do
      clear_db_of_fixture_data

      create_members
      create_policies
      create_policy_person_distances
    end

    it { compare_static '/feeds/mpdream-info.xml?id=1' }
    # This test is commented out because it occasionally fails on travis for unknown reasons
    # It doesn't fail when run locally
    # TODO Reinstate this test
    #it { compare_static '/feeds/mpdream-info.xml?id=2' }
  end
end
