# frozen_string_literal: true

require "spec_helper"

describe PeopleDistancesController, type: :controller do
  context "when member has a newer position/membership" do
    let(:policy) { create(:policy) }

    let!(:person1) { create(:person) }

    before do
      create(:member, person_id: person1.id, first_name: "Andrew", last_name: "Wilkie", house: "representatives", constituency: "Clark", entered_house: Date.new(2019, 5, 18), left_house: Date.new(9999, 12, 31))
      create(:member, person_id: person1.id, first_name: "Andrew", last_name: "Wilkie", house: "representatives", constituency: "Denison", entered_house: Date.new(2010, 8, 21), left_house: Date.new(2019, 5, 18))
      create(:policy_person_distance, person: person1, policy: policy)
    end

    describe "#show" do
      before do
        person = create(:person)
        create(:member, person_id: person.id, first_name: "Jane", last_name: "Smith", house: "representatives", constituency: "Foo")
        create(:people_distance, person1: person1, person2: person)
      end

      it "redirects older member to the canonical (latest) member" do
        get :show, params: { house: "representatives", mpc: "denison", mpn: "andrew_wilkie", house2: "representatives", mpc2: "foo", mpn2: "jane_smith" }

        expect(response).to redirect_to "/people/representatives/clark/andrew_wilkie/compare/representatives/foo/jane_smith"
      end

      it "redirects older member to the canonical (latest) member when it's in the second position too" do
        get :show, params: { house: "representatives", mpc: "foo", mpn: "jane_smith", house2: "representatives", mpc2: "denison", mpn2: "andrew_wilkie" }

        expect(response).to redirect_to "/people/representatives/foo/jane_smith/compare/representatives/clark/andrew_wilkie"
      end

      it "does not redirect the canonical member" do
        get :show, params: { house: "representatives", mpc: "clark", mpn: "andrew_wilkie", house2: "representatives", mpc2: "foo", mpn2: "jane_smith" }

        expect(response).to have_http_status :ok
      end
    end
  end

  describe "#policy" do
    let(:policy) { create(:policy) }
    let(:person1) { create(:person) }
    let(:person2) { create(:person) }
    let(:request_params) do
      { house: "representatives", mpc: "clark", mpn: "andrew_wilkie", house2: "representatives", mpc2: "foo", mpn2: "jane_smith", id: policy.id }
    end

    before do
      create(:member, person_id: person1.id, first_name: "Andrew", last_name: "Wilkie", house: "representatives", constituency: "Clark")
      create(:member, person_id: person2.id, first_name: "Jane", last_name: "Smith", house: "representatives", constituency: "Foo")
    end

    context "when the two people have been compared with each other" do
      before do
        create(:people_distance, person1: person1, person2: person2)
      end

      it "shows the comparison when both people have a distance for the policy" do
        create(:policy_person_distance, person: person1, policy: policy)
        create(:policy_person_distance, person: person2, policy: policy)

        get :policy, params: request_params

        expect(response).to have_http_status :ok
      end

      it "returns a 404 when the first person has no distance for the policy" do
        create(:policy_person_distance, person: person2, policy: policy)

        expect { get :policy, params: request_params }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it "returns a 404 when the second person has no distance for the policy" do
        create(:policy_person_distance, person: person1, policy: policy)

        expect { get :policy, params: request_params }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    it "returns a 404 when the two people haven't been compared with each other" do
      create(:policy_person_distance, person: person1, policy: policy)
      create(:policy_person_distance, person: person2, policy: policy)

      expect { get :policy, params: request_params }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
