# frozen_string_literal: true

require "spec_helper"

describe Division do
  describe "#formatted_motion_text" do
    it do
      division = described_class.new(motion: "A bill [No. 2] and votes")
      expect(division.formatted_motion_text).to eq("<p>A bill [No. 2] and votes</p>\n")
    end

    describe "update old site links" do
      context "when link points to publicwhip-test" do
        subject(:division) { described_class.new(motion: "<a href=\"http://publicwhip-test.openaustraliafoundation.org.au\">Foobar</a>") }

        it do
          expect(division.formatted_motion_text).to eq("<p><a href=\"https://theyvoteforyou.org.au\">Foobar</a></p>\n")
        end
      end

      context "when link points to publicwhip-rails" do
        subject(:division) { described_class.new(motion: "<a href=\"http://publicwhip-rails.openaustraliafoundation.org.au\">Foobar</a>") }

        it do
          expect(division.formatted_motion_text).to eq("<p><a href=\"https://theyvoteforyou.org.au\">Foobar</a></p>\n")
        end
      end
    end
  end

  describe "#passed?" do
    subject(:division) { described_class.new }

    it "is not passed when there's a draw" do
      allow(division).to receive(:aye_majority).and_return(0)
      expect(division.passed?).to be(false)
    end
  end

  # A division is loaded before its division_info cache row is built, so every
  # one of these has to cope with the association being nil rather than raise.
  # See https://github.com/openaustralia/theyvoteforyou/issues/1641
  describe "when the division_info cache hasn't been built yet" do
    subject(:division) { create(:division) }

    it "has no division_info" do
      expect(division.division_info).to be_nil
    end

    it "reports the outcome as not known" do
      expect(division.outcome_known?).to be(false)
    end

    describe "the delegated readers return nil rather than raising" do
      it { expect(division.aye_majority).to be_nil }
      it { expect(division.turnout).to be_nil }
      it { expect(division.rebellions).to be_nil }
      it { expect(division.majority).to be_nil }
      it { expect(division.majority_fraction).to be_nil }
    end

    describe "the predicates fall back to false rather than raising" do
      it { expect(division.passed?).to be(false) }
      it { expect(division.tied?).to be(false) }
      it { expect(division.unanimous?).to be(false) }
    end

    it "returns nil for total_votes" do
      expect(division.total_votes).to be_nil
    end

    it "returns nil for possible_votes" do
      expect(division.possible_votes).to be_nil
    end

    it "returns nil for attendance_fraction rather than dividing by nil" do
      expect(division.attendance_fraction).to be_nil
    end
  end

  describe "when the division_info cache has been built" do
    subject(:division) { create(:division) }

    before { create(:division_info, division: division, aye_majority: 5, turnout: 10, possible_turnout: 20, rebellions: 1) }

    it "reports the outcome as known" do
      expect(division.outcome_known?).to be(true)
    end

    it { expect(division.passed?).to be(true) }
    it { expect(division.tied?).to be(false) }
    it { expect(division.unanimous?).to be(false) }
    it { expect(division.total_votes).to eq(10) }
    it { expect(division.possible_votes).to eq(20) }
    it { expect(division.attendance_fraction).to eq(0.5) }
  end

  describe "::next_month" do
    it "returns the next month" do
      expect(described_class.next_month("2014-12")).to eq("2015-01-01")
    end
  end
end
