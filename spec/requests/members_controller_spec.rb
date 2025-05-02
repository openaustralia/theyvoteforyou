# frozen_string_literal: true

require "spec_helper"
# Compare results of rendering pages via rails and via the old php app

describe MembersController, type: :request do
  include HTMLCompareHelper
  include_context "with fixtures"

  describe "#index" do
    context "with members of the house of representatives" do
      before do
        # Current members
        member_tony_abbott
        member_john_alexander
        # Former member
        member_kevin_rudd
      end

      it { compare_static("/people/representatives") }
      it { compare_static("/people/representatives?sort=constituency") }
      it { compare_static("/people/representatives?sort=party") }
      it { compare_static("/people/representatives?sort=rebellions") }
      it { compare_static("/people/representatives?sort=attendance") }
    end

    context "with members of the senate" do
      before do
        # Current members
        member_christopher_back
        member_christine_milne
        # Former member
        member_judith_adams
      end

      it { compare_static("/people/senate") }
      it { compare_static("/people/senate?sort=constituency") }
      it { compare_static("/people/senate?sort=party") }
      it { compare_static("/people/senate?sort=rebellions") }
      it { compare_static("/people/senate?sort=attendance") }
    end
  end

  describe "#show" do
    describe "with tony abbott" do
      before do
        member_tony_abbott
        policy1_tony_abbott
        division_representatives_2006_12_06_3
        tony_abbott_tony_abbott
        tony_abbott_john_howard
        tony_abbott_maxine_mckew
        tony_abbott_kevin_rudd
        tony_abbott_john_alexander
      end

      it { compare_static("/people/representatives/warringah/tony_abbott") }
      it { compare_static("/people/representatives/warringah/tony_abbott/divisions") }
      it { compare_static("/people/representatives/warringah/tony_abbott/friends") }
      it { compare_static("/people/representatives/warringah/tony_abbott/policies/1") }
    end

    describe "with kevin rudd" do
      before do
        member_kevin_rudd
        policy1_kevin_rudd
        division_representatives_2006_12_06_3
        tony_abbott_kevin_rudd
        john_howard_kevin_rudd
        maxine_mckew_kevin_rudd
        kevin_rudd_kevin_rudd
        kevin_rudd_john_alexander
      end

      it { compare_static("/people/representatives/griffith/kevin_rudd") }
      it { compare_static("/people/representatives/griffith/kevin_rudd/divisions") }
      it { compare_static("/people/representatives/griffith/kevin_rudd/friends") }
      it { compare_static("/people/representatives/griffith/kevin_rudd/policies/1") }
    end

    describe "with christine milne" do
      before do
        member_christine_milne
        division_senate_2013_03_14_1
        division_senate_2009_12_30_8
        division_senate_2009_11_30_8
        division_representatives_2006_12_06_3
        christine_milne_christine_milne
        christine_milne_christopher_back
      end

      it { compare_static("/people/senate/tasmania/christine_milne") }
      it { compare_static("/people/senate/tasmania/christine_milne/divisions") }
      it { compare_static("/people/senate/tasmania/christine_milne/friends") }
    end

    it "404s when a policy comparison is unknown" do
      expect do
        member_christine_milne
        policy1
        get "/people/senate/tasmania/christine_milne/policies/1"
      end.to raise_error(ActiveRecord::RecordNotFound)
    end

    # Test free teller under Interesting Votes
    it do
      member_roger_price
      division_representatives_2006_12_06_3
      compare_static("/people/representatives/chifley/roger_price")
    end

    describe "with Barnaby Joyce" do
      before do
        division_senate_2013_03_14_1
        division_senate_2009_12_30_8
        division_senate_2009_11_30_8
        Person.create(id: 10350, large_image_url: "https://www.openaustralia.org.au/images/mpsL/10350.jpg")
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

      it { compare_static("/people/representatives/new_england/barnaby_joyce") }
    end

    it "404s when the wrong name is given for a correct electorate" do
      get "/people/representatives/warringah/foo_bar"
      expect(response).to have_http_status(:not_found)
    end
  end
end
