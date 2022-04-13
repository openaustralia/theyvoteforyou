# frozen_string_literal: true

require "spec_helper"

RSpec.describe PeopleDistance, type: :model do
  context "with two people who voted in some of the same divisions" do
    let(:person1) { create(:person) }
    let(:person2) { create(:person) }
    let(:member1a) { create(:member, person: person1) }
    let(:member1b) { create(:member, person: person1) }
    let(:member2a) { create(:member, person: person2) }
    let(:member2b) { create(:member, person: person2) }
    let(:division1) { create(:division) }
    let(:division2) { create(:division) }
    let(:division3) { create(:division) }
    let(:division4) { create(:division) }

    before do
      create(:vote, member: member1a, division: division1, vote: "aye")
      create(:vote, member: member1b, division: division2, vote: "aye")
      create(:vote, member: member1b, division: division3, vote: "aye")

      create(:vote, member: member2a, division: division2, vote: "aye")
      create(:vote, member: member2a, division: division3, vote: "no")
      create(:vote, member: member2b, division: division4, vote: "no")

      # Also this calculation all depends on the MemberDistance cache being updated
      MemberDistance.update_member(member1a)
      MemberDistance.update_member(member1b)
      MemberDistance.update_member(member2a)
      MemberDistance.update_member(member2b)
    end

    describe "#calculate_distances" do
      it "considers all members" do
        expect(described_class.calculate_distances(person1, person2)).to eq(
          nvotessame: 1,
          nvotesdiffer: 1,
          distance_b: 0.5
        )
      end
    end
  end
end
