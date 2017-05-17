require 'spec_helper'
# Compare results of rendering pages via rails and via the old php app

describe MembersController, type: :request do
  include HTMLCompareHelper

  describe "#index" do
    before(:each) do
      create_people_for_regression_tests
      create_members_for_regression_tests
      create_member_infos_for_regression_tests
    end

    it {compare_static("/mps.php?house=representatives")}
    it {compare_static("/mps.php?house=representatives&sort=constituency")}
    it {compare_static("/mps.php?house=representatives&sort=party")}
    it {compare_static("/mps.php?house=representatives&sort=rebellions")}
    it {compare_static("/mps.php?house=representatives&sort=attendance")}

    it {compare_static("/mps.php?house=senate")}
    it {compare_static("/mps.php?house=senate&sort=constituency")}
    it {compare_static("/mps.php?house=senate&sort=party")}
    it {compare_static("/mps.php?house=senate&sort=rebellions")}
    it {compare_static("/mps.php?house=senate&sort=attendance")}
  end

  describe "#show" do
    # TODO: Break this setup down into just what's needed for each example.
    #       This will speed up the tests, and also help us replace them with
    #       more specific and isolated tests.
    before(:each) do
      create_people_for_regression_tests
      create_members_for_regression_tests
      create_offices_for_regression_tests
      create_member_infos_for_regression_tests
      create_member_distances_for_regression_tests

      create_policies_for_regression_tests
      create_policy_person_distances_for_regression_tests

      create_divisions_for_regression_tests
      create_votes_for_regression_tests
      create_whips_for_regression_tests
      create_wiki_motions_for_regression_tests
    end

    it {compare_static("/mp.php?mpn=Tony_Abbott&mpc=Warringah&house=representatives")}
    it {compare_static("/mp.php?mpn=Kevin_Rudd&mpc=Griffith&house=representatives")}
    it {compare_static("/mp.php?mpn=Christine_Milne&mpc=Tasmania&house=senate")}

    it {compare_static("/mp.php?mpn=Tony_Abbott&mpc=Warringah&house=representatives&display=everyvote")}
    it {compare_static("/mp.php?mpn=Kevin_Rudd&mpc=Griffith&house=representatives&display=everyvote")}
    it {compare_static("/mp.php?mpn=Christine_Milne&mpc=Tasmania&house=senate&display=everyvote")}

    it {compare_static("/mp.php?mpn=Tony_Abbott&mpc=Warringah&house=representatives&display=allfriends")}
    it {compare_static("/mp.php?mpn=Kevin_Rudd&mpc=Griffith&house=representatives&display=allfriends")}
    it {compare_static("/mp.php?mpn=Christine_Milne&mpc=Tasmania&house=senate&display=allfriends")}

    context "with policy" do
      before :each do
        create_policy_divisions_for_regression_tests
      end

      it {compare_static("/mp.php?mpn=Tony_Abbott&mpc=Warringah&house=representatives&dmp=1")}
      it {compare_static("/mp.php?mpn=Kevin_Rudd&mpc=Griffith&house=representatives&dmp=1")}
      it {compare_static("/mp.php?mpn=Christine_Milne&mpc=Tasmania&house=senate&dmp=1")}
    end

    # Test free teller under Interesting Votes
    it {compare_static("/mp.php?mpn=Roger_Price&mpc=Chifley&house=representatives")}
  end

  describe "#show for Barnaby Joyce" do
    before :each do
      create_divisions_for_regression_tests
      create_votes_for_regression_tests
      create_whips_for_regression_tests
      create_wiki_motions_for_regression_tests

      Person.create(id: 10350, large_image_url: "http://www.openaustralia.org/images/mpsL/10350.jpg")
      Member.create(id: 664, gid: "uk.org.publicwhip/member/664", source_gid: "",
        first_name: "Barnaby", last_name: "Joyce", title: "", person_id: 10350,
        party: "National Party",
        house: "representatives", constituency: "New England",
        entered_house: "2013-09-07", left_house: "9999-12-31")
      Member.create(id: 100114, gid: "uk.org.publicwhip/lord/100114", source_gid: "",
        first_name: "Barnaby", last_name: "Joyce", title: "", person_id: 10350,
        party: "National Party",
        house: "senate", constituency: "Queensland",
        entered_house: "2005-07-01", left_house: "2013-08-08")

      Electorate.create(id: 143, name: "New England", main_name: true)
    end

    it { compare_static("/mp.php?mpn=Barnaby_Joyce&mpc=New_England&house=representatives") }

    # TODO: Should this be in spec/routing/redirects_spec.rb ?
    it "should redirect to the senator's page even if the id param incorrectly identifies a member as a senator and vice versa" do
      # Barnaby has been set up above as a member and a senator.
      # Let's refer to his senator record but incorrectly using `member` instead of `lord`
      get "/mp.php?id=uk.org.publicwhip/member/100114"
      expect(response.status).to eq 302
      expect(response.headers["location"]).to eq "/mp.php?house=senate&mpc=Queensland&mpn=Barnaby_Joyce"
    end
  end

  # TODO: Should this be in spec/controllers/members_controller_spec.rb ?
  it "should 404 with an unknown person" do
    get "/mp.php?mpn=Foo_Bar"
    expect(response.status).to eq 404
  end

  # TODO: Should this be in spec/controllers/members_controller_spec.rb ?
  it "should 404 when the wrong name is given for a correct electorate" do
    get "/people/representatives/warringah/foo_bar"
    expect(response.status).to eq(404)
  end
end
