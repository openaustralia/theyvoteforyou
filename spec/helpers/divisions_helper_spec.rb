require 'spec_helper'

describe DivisionsHelper, type: :helper do
  describe "#division_outcome" do
    context "Motion passed" do
      it { expect(helper.division_outcome(mock_model(Division, passed?: true))).to eq "Passed" }
    end

    context "Motion not passed" do
      it { expect(helper.division_outcome(mock_model(Division, passed?: false))).to eq "Not passed" }
    end
  end

  describe "#majority_strength_in_words" do
    before :each do
      allow(helper).to receive(:division_score).and_return('1 Aye – 0 No')
    end

    context "Motion with everyone voting one way" do
      it { expect(helper.majority_strength_in_words(mock_model(Division, majority_fraction: 1.0))).to eq "unanimously" }
    end

    context "Motion with a slight majority" do
      it { expect(helper.majority_strength_in_words(mock_model(Division, majority_fraction: 0.2))).to eq "by a <span class=\"has-tooltip\" title=\"1 Aye – 0 No\">small majority</span>" }
    end

    context "Motion with a modest majority" do
      it { expect(helper.majority_strength_in_words(mock_model(Division, majority_fraction: 0.5))).to eq "by a <span class=\"has-tooltip\" title=\"1 Aye – 0 No\">modest majority</span>" }
    end

    context "Motion with a large majority" do
      it { expect(helper.majority_strength_in_words(mock_model(Division, majority_fraction: 0.9))).to eq "by a <span class=\"has-tooltip\" title=\"1 Aye – 0 No\">large majority</span>" }
    end
  end
end
