# frozen_string_literal: true

require "spec_helper"
# Compare results of rendering pages via rails and via the old php app

describe MembersController, type: :request do
  include HTMLCompareHelper
  include_context "with fixtures"

  before do
    add_new_fixtures
  end

  describe "#index" do
    it { compare_static("/people/representatives") }
    it { compare_static("/people/representatives?sort=constituency") }
    it { compare_static("/people/representatives?sort=party") }
    it { compare_static("/people/representatives?sort=rebellions") }
    it { compare_static("/people/representatives?sort=attendance") }

    it { compare_static("/people/senate") }
    it { compare_static("/people/senate?sort=constituency") }
    it { compare_static("/people/senate?sort=party") }
    it { compare_static("/people/senate?sort=rebellions") }
    it { compare_static("/people/senate?sort=attendance") }
  end

  describe "#show" do
    it { compare_static("/people/representatives/warringah/tony_abbott") }
    it { compare_static("/people/representatives/griffith/kevin_rudd") }
    it { compare_static("/people/senate/tasmania/christine_milne") }

    it { compare_static("/people/representatives/warringah/tony_abbott/divisions") }
    it { compare_static("/people/representatives/griffith/kevin_rudd/divisions") }
    it { compare_static("/people/senate/tasmania/christine_milne/divisions") }

    it { compare_static("/people/representatives/warringah/tony_abbott/friends") }
    it { compare_static("/people/representatives/griffith/kevin_rudd/friends") }
    it { compare_static("/people/senate/tasmania/christine_milne/friends") }

    it { compare_static("/people/representatives/warringah/tony_abbott/policies/1") }
    it { compare_static("/people/representatives/griffith/kevin_rudd/policies/1") }

    it "404s when a policy comparison is unknown" do
      expect do
        get "/people/senate/tasmania/christine_milne/policies/1"
      end.to raise_error(ActiveRecord::RecordNotFound)
    end

    # Test free teller under Interesting Votes
    it { compare_static("/people/representatives/chifley/roger_price") }

    context "with Barnaby Joyce" do
      before do
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
      expect(response.status).to eq(404)
    end
  end
end
