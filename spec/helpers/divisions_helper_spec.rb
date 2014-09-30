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
    context "Motion with everyone voting one way" do
      it { expect(helper.majority_strength_in_words(mock_model(Division, majority_fraction: 1.0))).to eq "unanimously" }
    end

    context "Motion with a slight majority" do
      it { expect(helper.majority_strength_in_words(mock_model(Division, majority_fraction: 0.2))).to eq "by a small majority" }
    end

    context "Motion with a moderate majority" do
      it { expect(helper.majority_strength_in_words(mock_model(Division, majority_fraction: 0.5))).to eq "by a moderate majority" }
    end

    context "Motion with a large majority" do
      it { expect(helper.majority_strength_in_words(mock_model(Division, majority_fraction: 0.9))).to eq "by a large majority" }
    end
  end
end
