# frozen_string_literal: true

require "spec_helper"

describe DivisionSummaryPipeline::MemberResolver do
  describe ".resolve" do
    def create_downey_member(overrides = {})
      FactoryBot.create(:member, {
        person: FactoryBot.create(:person),
        first_name: "Alex",
        last_name: "Downey",
        constituency: "Brightwater",
        party: "Liberal",
        house: "representatives",
        entered_house: "2004-10-01",
        left_house: "9999-12-31"
      }.merge(overrides))
    end

    it "resolves an extracted name to the member's party, electorate and profile link" do
      create_downey_member

      resolved = described_class.resolve(name: "Alex Downey", house: "representatives", date: "2026-08-19")

      expect(resolved.name).to eq("Alex Downey")
      expect(resolved.party).to eq("Liberal")
      expect(resolved.electorate).to eq("Brightwater")
      expect(resolved.link).to eq("/people/representatives/brightwater/alex_downey")
    end

    it "resolves the member from the electorate when the Hansard text only states the seat" do
      create_downey_member

      resolved = described_class.resolve(electorate: "Brightwater", house: "representatives", date: "2026-08-19")

      expect(resolved.name).to eq("Alex Downey")
    end

    it "matches only members serving in the division's house" do
      create_downey_member
      create_downey_member(house: "senate", constituency: "Tasmania")

      resolved = described_class.resolve(name: "Alex Downey", house: "representatives", date: "2026-08-19")

      expect(resolved.electorate).to eq("Brightwater")
      expect(resolved.link).to eq("/people/representatives/brightwater/alex_downey")
    end

    it "keeps historical divisions pointed at the member who held the seat on the day" do
      create_downey_member(entered_house: "2004-10-01", left_house: "2010-10-01")
      create_downey_member(first_name: "Jordan", last_name: "McAllister", entered_house: "2010-10-02")

      historic = described_class.resolve(name: "Alex Downey", house: "representatives", date: "2008-03-01")
      current = described_class.resolve(name: "Alex Downey", house: "representatives", date: "2026-08-19")

      expect(historic.name).to eq("Alex Downey")
      expect(current.member).to be_nil
    end

    it "resolves senators with a nil electorate" do
      create_downey_member(house: "senate", constituency: "Tasmania")

      resolved = described_class.resolve(name: "Alex Downey", house: "senate", date: "2026-08-19")

      expect(resolved.electorate).to be_nil
      expect(resolved.link).to eq("/people/senate/tasmania/alex_downey")
    end

    it "returns a blank resolution when nothing matches" do
      resolved = described_class.resolve(name: "Nobody Person", house: "representatives", date: "2026-08-19")

      expect(resolved.member).to be_nil
      expect(resolved.name).to be_nil
      expect(resolved.party).to be_nil
      expect(resolved.link).to be_nil
    end
  end
end
