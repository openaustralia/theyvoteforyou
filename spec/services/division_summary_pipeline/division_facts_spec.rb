# frozen_string_literal: true

require "spec_helper"

describe DivisionSummaryPipeline::DivisionFacts do
  describe ".from a Hash" do
    it "reads the facts, and keeps what the caller supplies beyond them" do
      facts = described_class.from("house" => "senate", "date" => "2026-09-17", "number" => 10, "time" => "1:31 PM",
                                   "aye_votes" => 21, "no_votes" => 32, "result" => "Negatived",
                                   "digest_link" => "https://example.org/digest")

      expect(facts).to have_attributes(chamber: "Senate", other_chamber: "House of Representatives", turnout: 53,
                                       time: "1:31 PM", tied: false)
      expect(facts).not_to be_agreed
      expect(facts[:digest_link]).to eq("https://example.org/digest")
    end

    it "counts an equal vote as tied" do
      expect(described_class.from(aye_votes: 30, no_votes: 30)).to have_attributes(tied: true)
    end

    it "uses the recorded turnout when there is one" do
      expect(described_class.from(aye_votes: 30, no_votes: 20, turnout: 55).turnout).to eq(55)
    end

    it "adds the ayes and noes when no turnout is recorded" do
      expect(described_class.from(aye_votes: 30, no_votes: 20).turnout).to eq(50)
    end
  end

  describe ".from a Division" do
    it "reads the record and its bills" do
      division = create(:division, house: "senate", date: Date.new(2026, 9, 17), number: 10)
      division.bills << Bill.create!(official_id: "r9001", url: "http://example.org/r9001", title: "Example Bill 2026")
      division.bills << Bill.create!(official_id: "r9002", url: "http://example.org/r9002", title: "Example (Consequential) Bill 2026")

      facts = described_class.from(division)

      expect(facts).to have_attributes(house: "senate", date: "2026-09-17", number: 10, supplied: {})
      expect(facts.bill_name).to eq("Example Bill 2026 (and 1 related bill)")
    end
  end

  describe "#member_count" do
    let(:date) { Date.new(2026, 9, 17) }

    context "when the caller supplies the chamber size" do
      it "uses the supplied size" do
        facts = described_class.from(house: "senate", date: date.to_s, chamber_size: 76)

        expect(facts.member_count).to eq(76)
      end
    end

    context "when TVFY holds members who sat on the day" do
      before do
        create(:member, gid: "uk.org.publicwhip/lord/900001", house: "senate", entered_house: "2025-07-01", left_house: "9999-12-31")
        create(:member, gid: "uk.org.publicwhip/lord/900002", house: "senate", entered_house: "2025-07-01", left_house: "2026-01-01")
      end

      it "counts only the members current on that date in that house" do
        facts = described_class.from(house: "senate", date: date.to_s)

        expect(facts.member_count).to eq(1)
      end
    end

    context "when TVFY holds no members for the day" do
      it "is nil, so callers fall back to the guides' figures" do
        facts = described_class.from(house: "senate", date: date.to_s)

        expect(facts.member_count).to be_nil
      end
    end

    context "without a house or a date" do
      it "is nil" do
        expect(described_class.from(aye_votes: 3, no_votes: 2).member_count).to be_nil
      end
    end
  end

  # KNOWN_ISSUES.md KI-29: the draft called any majority over half the turnout "large", while
  # the division page beside it used different thresholds.
  describe ".majority_strength" do
    it "uses the division page's words and thresholds" do
      expect([0.9, 0.5, 0.2, 0.0, nil].map { |fraction| described_class.majority_strength(fraction) })
        .to eq(["large majority", "modest majority", "small majority", "majority", "majority"])
    end
  end
end
