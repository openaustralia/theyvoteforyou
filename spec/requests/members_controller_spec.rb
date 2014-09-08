require 'spec_helper'
# Compare results of rendering pages via rails and via the old php app

describe MembersController, :type => :request do
  include HTMLCompareHelper
  fixtures :all

  describe "#index" do
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
    it {compare_static("/mp.php?mpn=Tony_Abbott&mpc=Warringah&house=representatives")}
    it {compare_static("/mp.php?mpn=Kevin_Rudd&mpc=Griffith&house=representatives")}
    it {compare_static("/mp.php?mpn=Christine_Milne&mpc=Senate&house=senate", false, false, "_2")}

    it {compare_static("/mp.php?mpn=Tony_Abbott&mpc=Warringah&house=representatives&display=allvotes")}
    it {compare_static("/mp.php?mpn=Kevin_Rudd&mpc=Griffith&house=representatives&display=allvotes")}
    it {compare_static("/mp.php?mpn=Christine_Milne&mpc=Senate&house=senate&display=allvotes")}

    it {compare_static("/mp.php?mpn=Tony_Abbott&mpc=Warringah&house=representatives&display=everyvote")}
    it {compare_static("/mp.php?mpn=Kevin_Rudd&mpc=Griffith&house=representatives&display=everyvote")}
    it {compare_static("/mp.php?mpn=Christine_Milne&mpc=Senate&house=senate&display=everyvote")}

    it {compare_static("/mp.php?mpn=Tony_Abbott&mpc=Warringah&house=representatives&display=allfriends")}
    it {compare_static("/mp.php?mpn=Kevin_Rudd&mpc=Griffith&house=representatives&display=allfriends")}
    it {compare_static("/mp.php?mpn=Christine_Milne&mpc=Senate&house=senate&display=allfriends")}

    it {compare_static("/mp.php?mpn=Tony_Abbott&mpc=Warringah&house=representatives&dmp=1")}
    it {compare_static("/mp.php?mpn=Kevin_Rudd&mpc=Griffith&house=representatives&dmp=1")}
    it {compare_static("/mp.php?mpn=Christine_Milne&mpc=Senate&house=senate&dmp=1")}

    it {compare_static("/mp.php?mpn=Tony_Abbott&mpc=Warringah&house=representatives&dmp=1&display=motions")}
    it {compare_static("/mp.php?mpn=Kevin_Rudd&mpc=Griffith&house=representatives&dmp=1&display=motions")}
    it {compare_static("/mp.php?mpn=Christine_Milne&mpc=Senate&house=senate&dmp=1&display=motions")}

    # Test free teller under Interesting Votes
    it {compare_static("/mp.php?mpn=Roger_Price&mpc=Chifley&house=representatives")}

    context "Barnaby Joyce" do
      before :each do
        Member.create(id: 664, gid: "uk.org.publicwhip/member/664", source_gid: "",
          first_name: "Barnaby", last_name: "Joyce", title: "", person_id: 10350,
          party: "National Party",
          house: "commons", constituency: "New England",
          entered_house: "2013-09-07", left_house: "9999-12-31")
        Member.create(id: 100114, gid: "uk.org.publicwhip/lord/100114", source_gid: "",
          first_name: "Barnaby", last_name: "Joyce", title: "", person_id: 10350,
          party: "National Party",
          house: "lords", constituency: "Queensland",
          entered_house: "2005-07-01", left_house: "2013-08-08")

        Electorate.create(id: 143, name: "New England", main_name: true)
      end

      it { compare_static("/mp.php?mpn=Barnaby_Joyce") }
      it { compare_static("/mp.php?mpn=Barnaby_Joyce&mpc=New_England&house=representatives") }
    end

    it "should 404 with an unknown person" do
      get "/mp.php?mpn=Foo_Bar"
      expect(response.status).to eq 404
    end

    it "should 404 when the wrong name is given for a correct electorate" do
      get "/mp.php?house=representatives&mpc=Warringah&mpn=foo_bar"
      expect(response.status).to eq(404)
    end
  end
end
