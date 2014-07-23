require 'spec_helper'
# Compare results of rendering pages via rails and via the old php app

describe MembersController do
  include HTMLCompareHelper
  fixtures :all

  it "#index" do
    compare("/mps.php")
    compare("/mps.php?sort=lastname")
    compare("/mps.php?sort=constituency")
    compare("/mps.php?sort=party")
    compare("/mps.php?sort=rebellions")
    compare("/mps.php?sort=attendance")

    compare("/mps.php?house=senate")
    compare("/mps.php?house=senate&sort=lastname")
    compare("/mps.php?house=senate&sort=constituency")
    compare("/mps.php?house=senate&sort=party")
    compare("/mps.php?house=senate&sort=rebellions")
    compare("/mps.php?house=senate&sort=attendance")

    compare("/mps.php?house=all")
    compare("/mps.php?house=all&sort=lastname")
    compare("/mps.php?house=all&sort=constituency")
    compare("/mps.php?house=all&sort=party")
    compare("/mps.php?house=all&sort=rebellions")
    compare("/mps.php?house=all&sort=attendance")

    compare("/mps.php?parliament=all")
    compare("/mps.php?parliament=all&sort=lastname")
    compare("/mps.php?parliament=all&sort=constituency")
    compare("/mps.php?parliament=all&sort=party")
    compare("/mps.php?parliament=all&sort=rebellions")
    compare("/mps.php?parliament=all&sort=attendance")
    compare("/mps.php?parliament=all&house=senate")
    compare("/mps.php?parliament=all&house=senate&sort=lastname")
    compare("/mps.php?parliament=all&house=senate&sort=constituency")
    compare("/mps.php?parliament=all&house=senate&sort=party")
    compare("/mps.php?parliament=all&house=senate&sort=rebellions")
    compare("/mps.php?parliament=all&house=senate&sort=attendance")
    compare("/mps.php?parliament=all&house=all")
    compare("/mps.php?parliament=all&house=all&sort=lastname")
    compare("/mps.php?parliament=all&house=all&sort=constituency")
    compare("/mps.php?parliament=all&house=all&sort=party")
    compare("/mps.php?parliament=all&house=all&sort=rebellions")
    compare("/mps.php?parliament=all&house=all&sort=attendance")

    compare("/mps.php?parliament=2013")
    compare("/mps.php?parliament=2013&sort=lastname")
    compare("/mps.php?parliament=2013&sort=constituency")
    compare("/mps.php?parliament=2013&sort=party")
    compare("/mps.php?parliament=2013&sort=rebellions")
    compare("/mps.php?parliament=2013&sort=attendance")
    compare("/mps.php?parliament=2013&house=senate")
    compare("/mps.php?parliament=2013&house=senate&sort=lastname")
    compare("/mps.php?parliament=2013&house=senate&sort=constituency")
    compare("/mps.php?parliament=2013&house=senate&sort=party")
    compare("/mps.php?parliament=2013&house=senate&sort=rebellions")
    compare("/mps.php?parliament=2013&house=senate&sort=attendance")
    compare("/mps.php?parliament=2013&house=all")
    compare("/mps.php?parliament=2013&house=all&sort=lastname")
    compare("/mps.php?parliament=2013&house=all&sort=constituency")
    compare("/mps.php?parliament=2013&house=all&sort=party")
    compare("/mps.php?parliament=2013&house=all&sort=rebellions")
    compare("/mps.php?parliament=2013&house=all&sort=attendance")

    compare("/mps.php?parliament=2010")
    compare("/mps.php?parliament=2010&sort=lastname")
    compare("/mps.php?parliament=2010&sort=constituency")
    compare("/mps.php?parliament=2010&sort=party")
    compare("/mps.php?parliament=2010&sort=rebellions")
    compare("/mps.php?parliament=2010&sort=attendance")
    compare("/mps.php?parliament=2010&house=senate")
    compare("/mps.php?parliament=2010&house=senate&sort=lastname")
    compare("/mps.php?parliament=2010&house=senate&sort=constituency")
    compare("/mps.php?parliament=2010&house=senate&sort=party")
    compare("/mps.php?parliament=2010&house=senate&sort=rebellions")
    compare("/mps.php?parliament=2010&house=senate&sort=attendance")
    compare("/mps.php?parliament=2010&house=all")
    compare("/mps.php?parliament=2010&house=all&sort=lastname")
    compare("/mps.php?parliament=2010&house=all&sort=constituency")
    compare("/mps.php?parliament=2010&house=all&sort=party")
    compare("/mps.php?parliament=2010&house=all&sort=rebellions")
    compare("/mps.php?parliament=2010&house=all&sort=attendance")

    compare("/mps.php?parliament=2007")
    compare("/mps.php?parliament=2007&sort=lastname")
    compare("/mps.php?parliament=2007&sort=constituency")
    compare("/mps.php?parliament=2007&sort=party")
    compare("/mps.php?parliament=2007&sort=rebellions")
    compare("/mps.php?parliament=2007&sort=attendance")
    compare("/mps.php?parliament=2007&house=senate")
    compare("/mps.php?parliament=2007&house=senate&sort=lastname")
    compare("/mps.php?parliament=2007&house=senate&sort=constituency")
    compare("/mps.php?parliament=2007&house=senate&sort=party")
    compare("/mps.php?parliament=2007&house=senate&sort=rebellions")
    compare("/mps.php?parliament=2007&house=senate&sort=attendance")
    compare("/mps.php?parliament=2007&house=all")
    compare("/mps.php?parliament=2007&house=all&sort=lastname")
    compare("/mps.php?parliament=2007&house=all&sort=constituency")
    compare("/mps.php?parliament=2007&house=all&sort=party")
    compare("/mps.php?parliament=2007&house=all&sort=rebellions")
    compare("/mps.php?parliament=2007&house=all&sort=attendance")

    compare("/mps.php?parliament=2004")
    compare("/mps.php?parliament=2004&sort=lastname")
    compare("/mps.php?parliament=2004&sort=constituency")
    compare("/mps.php?parliament=2004&sort=party")
    compare("/mps.php?parliament=2004&sort=rebellions")
    compare("/mps.php?parliament=2004&sort=attendance")
    compare("/mps.php?parliament=2004&house=senate")
    compare("/mps.php?parliament=2004&house=senate&sort=lastname")
    compare("/mps.php?parliament=2004&house=senate&sort=constituency")
    compare("/mps.php?parliament=2004&house=senate&sort=party")
    compare("/mps.php?parliament=2004&house=senate&sort=rebellions")
    compare("/mps.php?parliament=2004&house=senate&sort=attendance")
    compare("/mps.php?parliament=2004&house=all")
    compare("/mps.php?parliament=2004&house=all&sort=lastname")
    compare("/mps.php?parliament=2004&house=all&sort=constituency")
    compare("/mps.php?parliament=2004&house=all&sort=party")
    compare("/mps.php?parliament=2004&house=all&sort=rebellions")
    compare("/mps.php?parliament=2004&house=all&sort=attendance")
  end

  describe "#show" do
    it do
      compare("/mp.php?mpn=Tony_Abbott&mpc=Warringah&house=representatives")
      compare("/mp.php?mpn=Kevin_Rudd&mpc=Griffith&house=representatives")
      compare("/mp.php?mpn=Christine_Milne&mpc=Senate&house=senate")

      compare("/mp.php?mpn=Tony_Abbott&mpc=Warringah&house=representatives&display=allvotes")
      compare("/mp.php?mpn=Kevin_Rudd&mpc=Griffith&house=representatives&display=allvotes")
      compare("/mp.php?mpn=Christine_Milne&mpc=Senate&house=senate&display=allvotes")

      compare("/mp.php?mpn=Tony_Abbott&mpc=Warringah&house=representatives&display=everyvote")
      compare("/mp.php?mpn=Kevin_Rudd&mpc=Griffith&house=representatives&display=everyvote")
      compare("/mp.php?mpn=Christine_Milne&mpc=Senate&house=senate&display=everyvote")

      compare("/mp.php?mpn=Tony_Abbott&mpc=Warringah&house=representatives&display=allfriends")
      compare("/mp.php?mpn=Kevin_Rudd&mpc=Griffith&house=representatives&display=allfriends")
      compare("/mp.php?mpn=Christine_Milne&mpc=Senate&house=senate&display=allfriends")

      compare("/mp.php?mpn=Tony_Abbott&mpc=Warringah&house=representatives&display=alldreams")
      compare("/mp.php?mpn=Kevin_Rudd&mpc=Griffith&house=representatives&display=alldreams")
      compare("/mp.php?mpn=Christine_Milne&mpc=Senate&house=senate&display=alldreams")

      compare("/mp.php?mpn=Tony_Abbott&mpc=Warringah&house=representatives&dmp=1")
      compare("/mp.php?mpn=Kevin_Rudd&mpc=Griffith&house=representatives&dmp=1")
      compare("/mp.php?mpn=Christine_Milne&mpc=Senate&house=senate&dmp=1")

      compare("/mp.php?mpn=Tony_Abbott&mpc=Warringah&house=representatives&dmp=1&display=motions")
      compare("/mp.php?mpn=Kevin_Rudd&mpc=Griffith&house=representatives&dmp=1&display=motions")
      compare("/mp.php?mpn=Christine_Milne&mpc=Senate&house=senate&dmp=1&display=motions")

      compare("/mp.php?mpc=Warringah")
      compare("/mp.php?mpc=Bennelong")

      compare("/mp.php?mpid=1&dmp=1")
      compare("/mp.php?id=uk.org.publicwhip/member/1")
      compare("/mp.php?id=uk.org.publicwhip/member/1&showall=yes")

      # Test free teller under Interesting Votes
      compare("/mp.php?mpn=Roger_Price&mpc=Chifley&house=representatives")
    end

    context "Barnaby Joyce" do
      before :each do
        Member.create(mp_id: 664, gid: "uk.org.publicwhip/member/664", source_gid: "",
          first_name: "Barnaby", last_name: "Joyce", title: "", person: 10350,
          party: "National Party",
          house: "commons", constituency: "New England",
          entered_house: "2013-09-07", left_house: "9999-12-31")
        Member.create(mp_id: 100114, gid: "uk.org.publicwhip/lord/100114", source_gid: "",
          first_name: "Barnaby", last_name: "Joyce", title: "", person: 10350,
          party: "National Party",
          house: "lords", constituency: "Queensland",
          entered_house: "2005-07-01", left_house: "2013-08-08")

        #<Member mp_id: 664, gid: "uk.org.publicwhip/member/664", source_gid: "",
        #first_name: "Barnaby", last_name: "Joyce", title: "", constituency: "New England",
        #party: "National Party", house: "commons", entered_house: "2013-09-07",
        #left_house: "9999-12-31", entered_reason: "general_election",
        #left_reason: "still_in_office", person: 10350>

        #<Member mp_id: 100114, gid: "uk.org.publicwhip/lord/100114", source_gid: "",
        #first_name: "Barnaby", last_name: "Joyce", title: "", constituency: "Queensland",
        #party: "National Party", house: "lords", entered_house: "2005-07-01",
        #left_house: "2013-08-08", entered_reason: "general_election",
        #left_reason: "resigned", person: 10350>

        Electorate.create(cons_id: 143, name: "New England", main_name: true)
        #<Electorate cons_id: 143, name: "New England", main_name: true, from_date: "1000-01-01",
        #to_date: "9999-12-31", house: "commons">
      end

      it { compare("/mp.php?mpid=664") }
      it { compare("/mp.php?id=uk.org.publicwhip/member/664") }
      it { compare("/mp.php?mpn=Barnaby_Joyce") }
      it { compare("/mp.php?mpn=Barnaby_Joyce&mpc=New_England&house=representatives") }
    end
  end
end
