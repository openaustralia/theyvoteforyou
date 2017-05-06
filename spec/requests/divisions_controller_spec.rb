require 'spec_helper'
# Compare results of rendering pages via rails and via the old php app

describe DivisionsController, type: :request do
  include HTMLCompareHelper
  describe "#show" do
    context "when user not signed in" do
      before :each do
        create_users
        create_people
        create_members
        create_policies
        create_divisions
        create_policy_divisions
        create_whips
        create_votes
        create_wiki_motions
      end

      it {compare_static("/division.php?date=2013-03-14&number=1&house=representatives")}
      it {compare_static("/division.php?date=2013-03-14&number=1&house=senate")}
      it {compare_static("/division.php?date=2013-03-14&number=1&house=representatives&display=policies", false, false, "_2")}
      it {compare_static("/division.php?date=2013-03-14&number=1&house=senate&display=policies", false, false, "_2")}

      it {compare_static("/division.php?date=2006-12-06&number=3&house=representatives")}
      # house=representatives or house=senate appears twice. This is obviously wrong
      it {compare_static("/division.php?date=2006-12-06&number=3&mpn=Tony_Abbott&mpc=Warringah&house=representatives&house=representatives")}
      it {compare_static("/division.php?date=2006-12-06&number=3&mpn=Kevin_Rudd&mpc=Griffith&house=representatives&house=representatives")}
      it {compare_static("/division.php?date=2013-03-14&number=1&mpn=Christine_Milne&mpc=Senate&house=senate&house=senate")}
    end

    context "when user signed in" do
      before :each do
        create_users
        create_members
        create_policies
        create_divisions
        create_policy_divisions
        create_whips
        create_votes
        create_wiki_motions
      end

      before :all do
        # TODO: We should setting a user here and passing it to compare_static
        #       Currently it's set in compare_static, which is not what you'd expect
        # create_users
      end

      it {compare_static("/division.php?date=2013-03-14&number=1&house=representatives&display=policies", true)}
      it {compare_static("/division.php?date=2013-03-14&number=1&house=senate&display=policies", true)}
      it {compare_static("/division.php?date=2009-11-25&number=8&house=senate&display=policies", true)}
      it {compare_static("/division.php?date=2009-11-25&number=8&house=senate&display=policies&dmp=2", true)}
      it {compare_static("/division.php?date=2009-11-25&number=8&house=senate&display=policies&dmp=1", true)}
      it {compare_static("/division.php?date=2006-12-06&house=representatives&number=3&display=policies", true)}
    end
  end

  describe "#index" do
    before :each do
      create_divisions
      create_whips
      create_wiki_motions
    end

    it {compare_static("/divisions.php")}
    it {compare_static("/divisions.php?rdisplay=2007")}
    it {compare_static("/divisions.php?rdisplay=2004")}
    it {compare_static("/divisions.php?rdisplay=all")}
    it {compare_static("/divisions.php?house=representatives")}
    it {compare_static("/divisions.php?rdisplay=2007&house=representatives")}
    it {compare_static("/divisions.php?rdisplay=2004&house=representatives")}
    it {compare_static("/divisions.php?rdisplay=all&house=representatives")}
    it {compare_static("/divisions.php?house=senate")}
    it {compare_static("/divisions.php?rdisplay=2007&house=senate")}
    it {compare_static("/divisions.php?rdisplay=2004&house=senate")}
    it {compare_static("/divisions.php?rdisplay=all&house=senate")}

    it {compare_static("/divisions.php?sort=subject")}
    it {compare_static("/divisions.php?rdisplay=2007&sort=subject")}
    it {compare_static("/divisions.php?rdisplay=2004&sort=subject")}
    it {compare_static("/divisions.php?rdisplay=all&sort=subject")}
    it {compare_static("/divisions.php?house=representatives&sort=subject")}
    it {compare_static("/divisions.php?rdisplay=2007&house=representatives&sort=subject")}
    it {compare_static("/divisions.php?rdisplay=2004&house=representatives&sort=subject")}
    it {compare_static("/divisions.php?rdisplay=all&house=representatives&sort=subject")}
    it {compare_static("/divisions.php?house=senate&sort=subject")}
    it {compare_static("/divisions.php?rdisplay=2007&house=senate&sort=subject")}
    it {compare_static("/divisions.php?rdisplay=2004&house=senate&sort=subject")}
    it {compare_static("/divisions.php?rdisplay=all&house=senate&sort=subject")}

    it {compare_static("/divisions.php?sort=rebellions")}
    it {compare_static("/divisions.php?rdisplay=2007&sort=rebellions")}
    it {compare_static("/divisions.php?rdisplay=2004&sort=rebellions")}
    it {compare_static("/divisions.php?rdisplay=all&sort=rebellions")}
    it {compare_static("/divisions.php?house=representatives&sort=rebellions")}
    it {compare_static("/divisions.php?rdisplay=2007&house=representatives&sort=rebellions")}
    it {compare_static("/divisions.php?rdisplay=2004&house=representatives&sort=rebellions")}
    it {compare_static("/divisions.php?rdisplay=all&house=representatives&sort=rebellions")}
    it {compare_static("/divisions.php?house=senate&sort=rebellions")}
    it {compare_static("/divisions.php?rdisplay=2007&house=senate&sort=rebellions")}
    it {compare_static("/divisions.php?rdisplay=2004&house=senate&sort=rebellions")}
    it {compare_static("/divisions.php?rdisplay=all&house=senate&sort=rebellions")}

    it {compare_static("/divisions.php?sort=turnout")}
    it {compare_static("/divisions.php?rdisplay=2007&sort=turnout")}
    it {compare_static("/divisions.php?rdisplay=2004&sort=turnout")}
    it {compare_static("/divisions.php?rdisplay=all&sort=turnout")}
    it {compare_static("/divisions.php?house=representatives&sort=turnout")}
    it {compare_static("/divisions.php?rdisplay=2007&house=representatives&sort=turnout")}
    it {compare_static("/divisions.php?rdisplay=2004&house=representatives&sort=turnout")}
    it {compare_static("/divisions.php?rdisplay=all&house=representatives&sort=turnout")}
    it {compare_static("/divisions.php?house=senate&sort=turnout")}
    it {compare_static("/divisions.php?rdisplay=2007&house=senate&sort=turnout")}
    it {compare_static("/divisions.php?rdisplay=2004&house=senate&sort=turnout")}
    it {compare_static("/divisions.php?rdisplay=all&house=senate&sort=turnout")}

    it {compare_static("/divisions.php?rdisplay2=Australian%20Labor%20Party_party&house=representatives")}
    it {compare_static("/divisions.php?rdisplay2=Liberal%20Party_party&house=representatives")}
    it {compare_static("/divisions.php?rdisplay2=Australian%20Greens_party&house=senate")}

    it {compare_static("/divisions.php?rdisplay2=Australian%20Labor%20Party_party&house=representatives&sort=subject")}
    it {compare_static("/divisions.php?rdisplay2=Liberal%20Party_party&house=representatives&sort=subject")}
    it {compare_static("/divisions.php?rdisplay2=Australian%20Greens_party&house=senate&sort=subject")}

    it {compare_static("/divisions.php?rdisplay2=Australian%20Labor%20Party_party&house=representatives&sort=rebellions")}
    it {compare_static("/divisions.php?rdisplay2=Liberal%20Party_party&house=representatives&sort=rebellions")}
    it {compare_static("/divisions.php?rdisplay2=Australian%20Greens_party&house=senate&sort=rebellions")}

    it {compare_static("/divisions.php?rdisplay2=Australian%20Labor%20Party_party&house=representatives&sort=turnout")}
    it {compare_static("/divisions.php?rdisplay2=Liberal%20Party_party&house=representatives&sort=turnout")}
    it {compare_static("/divisions.php?rdisplay2=Australian%20Greens_party&house=senate&sort=turnout")}

    it {compare_static("/divisions.php?rdisplay=2007&rdisplay2=Australian%20Labor%20Party_party&house=representatives")}
  end

  describe '#edit' do
    before :each do
      create_users
      # TODO: surely we don't need to create all these division to show one?
      create_divisions
      create_wiki_motions
    end

    it { compare_static '/account/wiki.php?type=motion&date=2009-11-25&number=8&house=senate&rr=%2Fdivision.php%3Fdate%3D2009-11-25%26number%3D8%26house%3Dsenate', true }
    it { compare_static '/account/wiki.php?type=motion&date=2013-03-14&number=1&house=representatives&rr=%2Fdivision.php%3Fdate%3D2013-03-14%26number%3D1%26house%3Drepresentatives', true }
  end

  describe '#update' do
    before :each do
      create_members
      # TODO: surely we don't need to create all these division to show one?
      create_divisions
      create_votes
      create_whips
      create_wiki_motions
    end

    it { compare_static '/divisions/senate/2009-11-25/8', true, submit: 'Save', newtitle: 'A lovely new title', newdescription: 'And a great new description' }
  end
end
