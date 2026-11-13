# frozen_string_literal: true

require "spec_helper"

# Regression cover for the HTML pages that 500'd when a division had been loaded
# but its division_info cache row hadn't been built yet.
# See https://github.com/openaustralia/theyvoteforyou/issues/1641
describe DivisionsController, type: :request do
  let!(:division) do
    create(:division, date: Date.new(2014, 1, 1), number: 1, house: "representatives", name: "An uncached division")
  end

  it "has no division_info, which is the state under test" do
    expect(division.division_info).to be_nil
  end

  describe "the divisions index" do
    before { get "/divisions/all" }

    it { expect(response).to have_http_status(:ok) }

    it "lists the division" do
      expect(response.body).to include("An uncached division")
    end

    it "says the outcome is unknown rather than claiming one" do
      expect(response.body).to include("Unknown")
    end

    it "doesn't claim the division passed or failed" do
      expect(response.body).not_to include("division-outcome-passed", "division-outcome-not-passed")
    end
  end

  describe "when the cache has been built" do
    before do
      create(:division_info, division: division, aye_majority: 10, turnout: 100, possible_turnout: 150)
      get "/divisions/all"
    end

    it { expect(response).to have_http_status(:ok) }

    it "reports the real outcome" do
      expect(response.body).to include("division-outcome-passed")
    end
  end
end
