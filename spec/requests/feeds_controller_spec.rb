require 'spec_helper'

describe FeedsController, type: :request do
  include HTMLCompareHelper

  describe '#mp-info' do
    before :each do
      create_divisions
      create_people
      create_members
      create_member_infos
    end

    context "for representatives" do
      it { compare_static '/feeds/mp-info.xml' }
    end

    context "for senators" do
      it { compare_static '/feeds/mp-info.xml?house=senate' }
    end
  end

  describe '#mpdream-info' do
    before do
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
