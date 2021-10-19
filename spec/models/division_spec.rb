# frozen_string_literal: true

require "spec_helper"

describe Division, type: :model do
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

    it "should not be passed when there's a draw" do
      allow(division).to receive(:aye_majority) { 0 }
      expect(division.passed?).to be(false)
    end
  end

  describe "::next_month" do
    it "returns the next month" do
      expect(described_class.next_month("2014-12")).to eq("2015-01-01")
    end
  end
end
