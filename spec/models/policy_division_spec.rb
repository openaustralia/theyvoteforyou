require "spec_helper"

describe PolicyDivision, type: :model do
  describe "#vote" do
    it { expect(PolicyDivision.new(policy: Policy.new, division: Division.new)).not_to be_valid }
    it { expect(PolicyDivision.new(policy: Policy.new, division: Division.new, vote: "aye3")).to be_valid }
    it { expect(PolicyDivision.new(policy: Policy.new, division: Division.new, vote: "aye")).to be_valid }
    it { expect(PolicyDivision.new(policy: Policy.new, division: Division.new, vote: "no")).to be_valid }
    it { expect(PolicyDivision.new(policy: Policy.new, division: Division.new, vote: "no3")).to be_valid }
    it { expect(PolicyDivision.new(policy: Policy.new, division: Division.new, vote: "bottom")).not_to be_valid }
  end
end
