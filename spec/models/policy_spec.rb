# frozen_string_literal: true

require "spec_helper"

describe Policy do
  subject(:policy) { create(:policy) }

  it "is valid with a name longer than 50 characters" do
    user = create(:user)
    policy = build(:policy, user: user, name: "a-name-much-bigger-than-fifty-characters-a-very-long-name-indeed")

    expect(policy).to be_valid
  end

  it "is not valid with a name longer than 100 characters" do
    policy = build(:policy, name: "a-name-bigger-than-one-hundred-characters-is-such-a-long-name-for-a-policy-is-it-really-necessay? We’ll find out soon.")

    expect(policy).not_to be_valid
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
    let(:division1) { create(:division, house: "representatives", date: Date.new(2014, 1, 1)) }
    let(:division2) { create(:division, house: "representatives", date: Date.new(2014, 2, 1)) }
    let(:division3) { create(:division, house: "representatives", date: Date.new(2014, 3, 1)) }

    before do
      create(:policy_division, policy: policy, division: division1, vote: "aye")
      create(:policy_division, policy: policy, division: division2, vote: "no")
      create(:policy_division, policy: policy, division: division3, vote: "aye3")
    end

    describe "member could have voted but is absent for each vote on the policy" do
      let!(:member) { create(:member, house: "representatives", entered_house: Date.new(2005, 7, 1), left_house: Date.new(9999, 12, 31)) }

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

    describe "member was not in parliament during any of the votes" do
      let!(:member) { create(:member, house: "representatives", entered_house: Date.new(2015, 1, 1), left_house: Date.new(9999, 12, 31)) }

      it do
        policy.calculate_person_distances!
        ppd = PolicyPersonDistance.find_by(person: member.person, policy: policy)
        expect(ppd).to be_nil
      end
    end

    describe "member was in a different house to the ones where the divisions took place" do
      let!(:member) { create(:member, house: "senate", entered_house: Date.new(2005, 7, 1), left_house: Date.new(9999, 12, 31)) }

      it do
        policy.calculate_person_distances!
        ppd = PolicyPersonDistance.find_by(person: member.person, policy: policy)
        expect(ppd).to be_nil
      end
    end

    describe "member was present during two of the votes" do
      let!(:member) { create(:member, house: "representatives", entered_house: Date.new(2005, 7, 1), left_house: Date.new(9999, 12, 31)) }

      before do
        create(:vote, member: member, division: division1, vote: "aye")
        create(:vote, member: member, division: division3, vote: "no")
      end

      it do
        policy.calculate_person_distances!
        ppd = PolicyPersonDistance.find_by(person: member.person, policy: policy)
        expect(ppd.nvotessame).to eq 1
        expect(ppd.nvotessamestrong).to eq 0
        expect(ppd.nvotesdiffer).to eq 0
        expect(ppd.nvotesdifferstrong).to eq 1
        expect(ppd.nvotesabsent).to eq 1
        expect(ppd.nvotesabsentstrong).to eq 0
        expect(ppd.distance_a).to eq 0.822581
      end
    end

    describe "person has two members that voted on different divisions" do
      let(:person) { create(:person) }
      let!(:member1) { create(:member, person: person, house: "representatives", entered_house: Date.new(2005, 7, 1), left_house: Date.new(2014, 2, 2)) }
      let!(:member2) { create(:member, person: person, house: "representatives", entered_house: Date.new(2014, 2, 2), left_house: Date.new(9999, 12, 31)) }

      before do
        create(:vote, member: member1, division: division1, vote: "aye")
        create(:vote, member: member1, division: division2, vote: "no")
        create(:vote, member: member2, division: division3, vote: "no")
      end

      it do
        policy.calculate_person_distances!
        ppd = PolicyPersonDistance.find_by(person: person, policy: policy)
        expect(ppd.nvotessame).to eq 2
        expect(ppd.nvotessamestrong).to eq 0
        expect(ppd.nvotesdiffer).to eq 0
        expect(ppd.nvotesdifferstrong).to eq 1
        expect(ppd.nvotesabsent).to eq 0
        expect(ppd.nvotesabsentstrong).to eq 0
        expect(ppd.distance_a).to eq 0.714286
      end
    end
  end
end
