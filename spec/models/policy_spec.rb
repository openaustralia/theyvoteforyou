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

  describe "#current_members_very_strongly_for" do
    let(:person) { create(:person) }

    context "when member is current and voted very strongly for policy" do
      let!(:member) { create(:member, person: person) }

      before do
        create(:policy_person_distance, person: person, policy: policy, distance_a: 0.03)
      end

      it "returns the member" do
        expect(policy.current_members_very_strongly_for).to eq [member]
      end
    end

    context "when member is current and voted moderately for policy" do
      before do
        create(:member, person: person)
        create(:policy_person_distance, person: person, policy: policy, distance_a: 0.3)
      end

      it "returns nothing" do
        expect(policy.current_members_very_strongly_for).to be_empty
      end
    end

    context "when member has retired and voted very strongly for policy" do
      before do
        create(:member, person: person, left_house: "2006-01-01")
        create(:policy_person_distance, person: person, policy: policy, distance_a: 0.03)
      end

      it "returns nothing" do
        expect(policy.current_members_very_strongly_for).to be_empty
      end
    end

    context "when two current members that voted very strongly for the policy" do
      let(:person1) { create(:person) }
      let(:person2) { create(:person) }
      let!(:member1) { create(:member, person: person1, last_name: "Zebra") }
      let!(:member2) { create(:member, person: person2, last_name: "Alpha") }

      before do
        create(:policy_person_distance, person: person1, policy: policy, distance_a: 0.03)
        create(:policy_person_distance, person: person2, policy: policy, distance_a: 0.03)
      end

      it "sorts the members by name" do
        expect(policy.current_members_very_strongly_for).to eq [member2, member1]
      end
    end
  end
end
