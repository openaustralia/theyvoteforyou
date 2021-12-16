# frozen_string_literal: true

require "spec_helper"

describe MembersController, type: :controller do
  context "when member has a newer position/membership" do
    before do
      person = create(:person)
      create(:member, person_id: person.id, first_name: "Andrew", last_name: "Wilkie", house: "representatives", constituency: "Clark", entered_house: Date.new(2019, 5, 18), left_house: Date.new(9999, 12, 31))
      create(:member, person_id: person.id, first_name: "Andrew", last_name: "Wilkie", house: "representatives", constituency: "Denison", entered_house: Date.new(2010, 8, 21), left_house: Date.new(2019, 5, 18))
    end

    describe "#show" do
      it "redirects older member to the canonical (latest) member" do
        get :show, params: { house: "representatives", mpc: "denison", mpn: "andrew_wilkie" }

        expect(response).to redirect_to "/people/representatives/clark/andrew_wilkie"
      end

      it "does not redirect the canonical member" do
        get :show, params: { house: "representatives", mpc: "clark", mpn: "andrew_wilkie" }

        expect(response.status).to be 200
      end
    end

    describe "#friends" do
      it "redirects older member to the canonical (latest) member" do
        get :friends, params: { house: "representatives", mpc: "denison", mpn: "andrew_wilkie" }

        expect(response).to redirect_to "/people/representatives/clark/andrew_wilkie/friends"
      end

      it "does not redirect the canonical member" do
        get :friends, params: { house: "representatives", mpc: "clark", mpn: "andrew_wilkie" }

        expect(response.status).to be 200
      end
    end

    describe "#policy" do
      it "redirects older member to the canonical (latest) member" do
        get :policy, params: { house: "representatives", mpc: "denison", mpn: "andrew_wilkie", id: "1" }

        expect(response).to redirect_to "/people/representatives/clark/andrew_wilkie/policies/1"
      end

      it "does not redirect the canonical member" do
        get :policy, params: { house: "representatives", mpc: "clark", mpn: "andrew_wilkie", id: "1" }

        expect(response.status).to be 200
      end
    end

    describe "#compare" do
      before do
        person = create(:person)
        create(:member, person_id: person.id, first_name: "Jane", last_name: "Smith", house: "representatives", constituency: "Foo")
      end

      it "redirects older member to the canonical (latest) member" do
        get :compare, params: { house: "representatives", mpc: "denison", mpn: "andrew_wilkie", mpc2: "foo", mpn2: "jane_smith" }

        expect(response).to redirect_to "/people/representatives/clark/andrew_wilkie/compare/foo/jane_smith"
      end

      it "redirects older member to the canonical (latest) member when it's in the second position too" do
        get :compare, params: { house: "representatives", mpc: "foo", mpn: "jane_smith", mpc2: "denison", mpn2: "andrew_wilkie" }

        expect(response).to redirect_to "/people/representatives/foo/jane_smith/compare/clark/andrew_wilkie"
      end

      it "does not redirect the canonical member" do
        get :compare, params: { house: "representatives", mpc: "clark", mpn: "andrew_wilkie", mpc2: "foo", mpn2: "jane_smith" }

        expect(response.status).to be 200
      end
    end
  end
end
