require 'spec_helper'

describe DivisionParameterParser, type: :model do
  describe ".get_date_range" do
    it "gets range for complete date's format" do
      date_start, date_end, date_range = DivisionParameterParser.get_date_range('2017-12-20')

      expect(date_start).to eq(Date.new(2017, 12, 20))
      expect(date_end).to eq(Date.new(2017, 12, 21))
      expect(date_range).to eq(:day)
    end

    it "gets range for year and month date's format" do
      date_start, date_end, date_range = DivisionParameterParser.get_date_range('2017-12')

      expect(date_start).to eq(Date.new(2017, 12, 01))
      expect(date_end).to eq(Date.new(2018, 01, 01))
      expect(date_range).to eq(:month)
    end

    it "gets range for year only date's format" do
      date_start, date_end, date_range = DivisionParameterParser.get_date_range('2017')

      expect(date_start).to eq(Date.new(2017, 01, 01))
      expect(date_end).to eq(Date.new(2018, 01, 01))
      expect(date_range).to eq(:year)
    end

    it "raise exception for invalid date" do
      expect { DivisionParameterParser.get_date_range('2017-13-01') }.to raise_error(ArgumentError)
    end

    it "raise exception for date in the wrong format" do
      expect { DivisionParameterParser.get_date_range('2017-12-011') }.to raise_error(ArgumentError)
    end
  end
end
