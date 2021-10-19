# frozen_string_literal: true

require "spec_helper"

describe DivisionParameterParser, type: :model do
  describe ".date_range" do
    it "gets range for complete date's format" do
      date_start, date_end, date_range = described_class.date_range("2017-12-20")

      expect(date_start).to eq(Date.new(2017, 12, 20))
      expect(date_end).to eq(Date.new(2017, 12, 21))
      expect(date_range).to eq(:day)
    end

    it "gets range for year and month date's format" do
      date_start, date_end, date_range = described_class.date_range("2017-12")

      expect(date_start).to eq(Date.new(2017, 12, 1))
      expect(date_end).to eq(Date.new(2018, 1, 1))
      expect(date_range).to eq(:month)
    end

    it "gets range for year only date's format" do
      date_start, date_end, date_range = described_class.date_range("2017")

      expect(date_start).to eq(Date.new(2017, 1, 1))
      expect(date_end).to eq(Date.new(2018, 1, 1))
      expect(date_range).to eq(:year)
    end

    it "raise exception for invalid date" do
      expect { described_class.date_range("2017-13-01") }.to raise_error(ArgumentError)
    end

    it "raise exception for date in the wrong format" do
      expect { described_class.date_range("2017-12-011") }.to raise_error(ArgumentError)
    end
  end
end
