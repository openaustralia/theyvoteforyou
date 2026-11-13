# frozen_string_literal: true

require "spec_helper"

# The API reads possible_turnout and rebellions straight off division_info rather
# than through the delegation on Division, so it needs its own guard against the
# cache row not existing yet.
# See https://github.com/openaustralia/theyvoteforyou/issues/1641
describe Api::V1::DivisionsController, type: :request do
  let(:user) { create(:confirmed_user) }
  let(:key) { user.api_key }
  let(:division) do
    create(:division, date: Date.new(2014, 1, 1), number: 1, house: "representatives")
  end

  describe "#index" do
    context "when the division_info cache hasn't been built yet" do
      before { division }

      it "responds successfully rather than raising" do
        get "/api/v1/divisions.json", params: { key: key }
        expect(response).to have_http_status(:ok)
      end

      it "returns null for the values it can't calculate yet" do
        get "/api/v1/divisions.json", params: { key: key }
        expect(response.parsed_body.first).to include("possible_turnout" => nil, "rebellions" => nil)
      end

      it "still returns the division's own attributes" do
        get "/api/v1/divisions.json", params: { key: key }
        expect(response.parsed_body.first).to include("id" => division.id, "house" => "representatives")
      end
    end

    context "when the division_info cache has been built" do
      before do
        create(:division_info, division: division, possible_turnout: 150, rebellions: 2)
      end

      it "returns the cached values" do
        get "/api/v1/divisions.json", params: { key: key }
        expect(response.parsed_body.first).to include("possible_turnout" => 150, "rebellions" => 2)
      end
    end
  end

  describe "#show" do
    context "when the division_info cache hasn't been built yet" do
      it "responds successfully rather than raising" do
        get "/api/v1/divisions/#{division.id}.json", params: { key: key }
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "without an api key" do
    it "is unauthorized" do
      get "/api/v1/divisions.json"
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
