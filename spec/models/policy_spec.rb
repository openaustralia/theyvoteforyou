# frozen_string_literal: true

require "spec_helper"

describe Policy, type: :model do
  subject(:policy) { create(:policy) }

  it "is valid with a name longer than 50 characters" do
    user = create(:user)
    policy = build(:policy, user: user, name: "a-name-much-bigger-than-fifty-characters-a-very-long-name-indeed")

    expect(policy).to be_valid
  end

  it "is not valid with a name longer than 100 characters" do
    policy = build(:policy, name: "a-name-bigger-than-one-hundred-characters-is-such-a-long-name-for-a-policy-is-it-really-necessay? We’ll find out soon.")

    expect(policy).to be_invalid
    expect(policy.errors[:name]).to include("is too long (maximum is 100 characters)")
  end

  describe "#status" do
    it "private is 0" do
      policy.private = 0
      expect(policy.status).to eq "published"
    end

    it "private is 1" do
      policy.private = 1
      expect(policy.status).to eq "legacy Dream MP"
    end

    it "private is 2" do
      policy.private = 2
      expect(policy.status).to eq "provisional"
    end
  end

  describe "#provisional?" do
    it "private is 2" do
      policy.private = 2
      expect(policy.provisional?).to be true
    end

    it "private is 0" do
      policy.private = 0
      expect(policy.provisional?).to be false
    end
  end

  describe "#calculate_person_distances!" do
    # Look at a single member and see how their votes match against the policy
    before do
      create(:policy_division, policy: policy, vote: "aye")
      create(:policy_division, policy: policy, vote: "no")
      create(:policy_division, policy: policy, vote: "aye3")
    end

    describe "member could have voted but is absent for each vote on the policy" do
      let!(:member) { create(:member) }

      it do
        policy.calculate_person_distances!
        ppd = PolicyPersonDistance.find_by(person: member.person, policy: policy)
        expect(ppd.nvotessame).to eq 0
        expect(ppd.nvotessamestrong).to eq 0
        expect(ppd.nvotesdiffer).to eq 0
        expect(ppd.nvotesdifferstrong).to eq 0
        expect(ppd.nvotesabsent).to eq 2
        expect(ppd.nvotesabsentstrong).to eq 1
        expect(ppd.distance_a).to eq 0.5
      end
    end
  end
end
