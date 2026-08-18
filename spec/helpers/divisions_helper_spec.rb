# frozen_string_literal: true

require "spec_helper"

describe DivisionsHelper, type: :helper do
  describe "#division_outcome" do
    context "when motion passed" do
      it { expect(helper.division_outcome(mock_model(Division, outcome_known?: true, passed?: true))).to eq "Passed" }
    end

    context "when motion not passed" do
      it { expect(helper.division_outcome(mock_model(Division, outcome_known?: true, passed?: false))).to eq "Not passed" }
    end

    context "when the division_info cache hasn't been built yet" do
      it "doesn't claim an outcome it hasn't calculated" do
        expect(helper.division_outcome(mock_model(Division, outcome_known?: false))).to eq "Unknown"
      end
    end
  end

  describe "#division_outcome_class" do
    context "when motion passed" do
      it { expect(helper.division_outcome_class(mock_model(Division, outcome_known?: true, passed?: true))).to eq "division-outcome-passed" }
    end

    context "when motion not passed" do
      it { expect(helper.division_outcome_class(mock_model(Division, outcome_known?: true, passed?: false))).to eq "division-outcome-not-passed" }
    end

    context "when the division_info cache hasn't been built yet" do
      it { expect(helper.division_outcome_class(mock_model(Division, outcome_known?: false))).to eq "division-outcome-unknown" }
    end
  end

  describe "#majority_strength_in_words" do
    before do
      allow(helper).to receive(:division_score).and_return("1 Aye – 0 No")
    end

    context "with motion with everyone voting one way" do
      it do
        division = mock_model(Division, outcome_known?: true, majority_fraction: 1.0, unanimous?: true, tied?: false)
        expect(helper.majority_strength_in_words(division)).to eq "unanimously"
      end
    end

    context "with motion with a slight majority" do
      it do
        division = mock_model(Division, outcome_known?: true, majority_fraction: 0.2, unanimous?: false, tied?: false)
        expect(helper.majority_strength_in_words(division)).to eq "by a <span class=\"has-tooltip\" title=\"1 Aye – 0 No\">small majority</span>"
      end
    end

    context "with motion with a modest majority" do
      it do
        division = mock_model(Division, outcome_known?: true, majority_fraction: 0.5, unanimous?: false, tied?: false)
        expect(helper.majority_strength_in_words(division)).to eq "by a <span class=\"has-tooltip\" title=\"1 Aye – 0 No\">modest majority</span>"
      end
    end

    context "with motion with a large majority" do
      it do
        division = mock_model(Division, outcome_known?: true, majority_fraction: 0.9, unanimous?: false, tied?: false)
        expect(helper.majority_strength_in_words(division)).to eq "by a <span class=\"has-tooltip\" title=\"1 Aye – 0 No\">large majority</span>"
      end
    end

    context "when the division_info cache hasn't been built yet" do
      it "says nothing about the majority" do
        expect(helper.majority_strength_in_words(mock_model(Division, outcome_known?: false))).to eq ""
      end
    end
  end

  describe "#divisions_period" do
    context "with year specified" do
      it "returns year when present" do
        expect(helper.divisions_period(:year, Date.parse("2014-01-01"))).to eq "2014"
      end
    end

    context "with month specified" do
      it "returns formatted month when present" do
        expect(helper.divisions_period(:month, Date.parse("2014-06-01"))).to eq "June 2014"
      end
    end

    context "with date specified" do
      it "returns formatted date when present" do
        expect(helper.divisions_period(:day, Date.parse("2014-06-01"))).to eq "1st Jun 2014"
      end
    end
  end
end
