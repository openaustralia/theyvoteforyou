# frozen_string_literal: true

require "spec_helper"

describe DivisionsHelper, type: :helper do
  describe "#division_outcome" do
    context "when motion passed" do
      it { expect(helper.division_outcome(mock_model(Division, passed?: true))).to eq "Passed" }
    end

    context "when motion not passed" do
      it { expect(helper.division_outcome(mock_model(Division, passed?: false))).to eq "Not passed" }
    end
  end

  describe "#majority_strength_in_words" do
    before :each do
      allow(helper).to receive(:division_score).and_return("1 Aye – 0 No")
    end

    context "with motion with everyone voting one way" do
      it do
        division = mock_model(Division, majority_fraction: 1.0, unanimous?: true, tied?: false)
        expect(helper.majority_strength_in_words(division)).to eq "unanimously"
      end
    end

    context "with motion with a slight majority" do
      it do
        division = mock_model(Division, majority_fraction: 0.2, unanimous?: false, tied?: false)
        expect(helper.majority_strength_in_words(division)).to eq "by a <span class=\"has-tooltip\" title=\"1 Aye – 0 No\">small majority</span>"
      end
    end

    context "with motion with a modest majority" do
      it do
        division = mock_model(Division, majority_fraction: 0.5, unanimous?: false, tied?: false)
        expect(helper.majority_strength_in_words(division)).to eq "by a <span class=\"has-tooltip\" title=\"1 Aye – 0 No\">modest majority</span>"
      end
    end

    context "with motion with a large majority" do
      it do
        division = mock_model(Division, majority_fraction: 0.9, unanimous?: false, tied?: false)
        expect(helper.majority_strength_in_words(division)).to eq "by a <span class=\"has-tooltip\" title=\"1 Aye – 0 No\">large majority</span>"
      end
    end
  end

  describe "#divisions_period" do
    context "with year specified" do
      before do
        helper.instance_variable_set("@date_range", :year)
        helper.instance_variable_set("@date_start", Date.parse("2014-01-01"))
      end

      it "returns year when present" do
        expect(helper.divisions_period).to eq "2014"
      end
    end

    context "with month specified" do
      before do
        helper.instance_variable_set("@date_range", :month)
        helper.instance_variable_set("@date_start", Date.parse("2014-06-01"))
      end

      it "returns formatted month when present" do
        expect(helper.divisions_period).to eq "June 2014"
      end
    end

    context "with date specified" do
      before do
        helper.instance_variable_set("@date_range", :day)
        helper.instance_variable_set("@date_start", Date.parse("2014-06-01"))
      end

      it "returns formatted date when present" do
        expect(helper.divisions_period).to eq "1st Jun 2014"
      end
    end
  end
end
