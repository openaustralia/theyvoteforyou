# frozen_string_literal: true

require "spec_helper"

RSpec.describe PeopleDistance do
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

    describe "#update_person" do
      before do
        described_class.update_person(person1)
      end

      it "creates three records" do
        expect(described_class.count).to eq 3
      end

      it "gives the expected result comparing person1 to person2" do
        r = described_class.find_by(person1: person1, person2: person2)
        expect(r.nvotessame).to eq 1
        expect(r.nvotesdiffer).to eq 1
        expect(r.distance_b).to eq 0.5
      end

      it "gives the expected result comparing person2 to person1" do
        r = described_class.find_by(person1: person2, person2: person1)
        expect(r.nvotessame).to eq 1
        expect(r.nvotesdiffer).to eq 1
        expect(r.distance_b).to eq 0.5
      end

      it "gives the expected result comparing person1 to themselves" do
        r = described_class.find_by(person1: person1, person2: person1)
        expect(r.nvotessame).to eq 3
        expect(r.nvotesdiffer).to eq 0
        expect(r.distance_b).to eq 0
      end
    end
  end

  describe "#overlap_dates" do
    context "when two members who were there some of the same time" do
      let(:member1) { create(:member, entered_house: Date.new(2000, 1, 1), left_house: Date.new(2002, 1, 1)) }
      let(:member2) { create(:member, entered_house: Date.new(2001, 1, 1), left_house: Date.new(2003, 1, 1)) }

      it "only returns the date range for when both members were in parliament" do
        d = build(:people_distance, person1: member1.person, person2: member2.person)
        # Note the exclusive range here (three dots)
        expect(d.overlap_dates).to eq [Date.new(2001, 1, 1)...Date.new(2002, 1, 1)]
      end

      it "returns the same date range if the order of the members is reversed" do
        d = build(:people_distance, person1: member2.person, person2: member1.person)
        expect(d.overlap_dates).to eq [Date.new(2001, 1, 1)...Date.new(2002, 1, 1)]
      end

      context "when one person has two almost consecutive memberships" do
        before do
          create(:member, entered_house: Date.new(2002, 2, 1), left_house: Date.new(2004, 1, 1), person: member1.person)
        end

        it "returns multiple date ranges" do
          expect(member1.person.members.count).to eq 2
          d = build(:people_distance, person1: member1.person, person2: member2.person)
          expect(d.overlap_dates).to eq [Date.new(2001, 1, 1)...Date.new(2002, 1, 1), Date.new(2002, 2, 1)...Date.new(2003, 1, 1)]
        end
      end

      context "when one person has two consecutive memberships" do
        before do
          create(:member, entered_house: Date.new(2002, 1, 1), left_house: Date.new(2004, 1, 1), person: member1.person)
        end

        it "returns one merged date range" do
          expect(member1.person.members.count).to eq 2
          d = build(:people_distance, person1: member1.person, person2: member2.person)
          expect(d.overlap_dates).to eq [Date.new(2001, 1, 1)...Date.new(2003, 1, 1)]
        end
      end
    end

    context "when two member have not overlapped at all" do
      let(:member1) { create(:member, entered_house: Date.new(2000, 1, 1), left_house: Date.new(2001, 1, 1)) }
      let(:member2) { create(:member, entered_house: Date.new(2002, 1, 1), left_house: Date.new(2003, 1, 1)) }

      it "returns an empty array because there is no overlap" do
        d = build(:people_distance, person1: member1.person, person2: member2.person)
        expect(d.overlap_dates).to eq []
      end
    end

    context "when two members in different houses" do
      let(:member1) { create(:member, entered_house: Date.new(2000, 1, 1), left_house: Date.new(2002, 1, 1), house: "representatives") }
      let(:member2) { create(:member, entered_house: Date.new(2001, 1, 1), left_house: Date.new(2003, 1, 1), house: "senate") }

      it "returns an empty array because there is no overlap" do
        d = build(:people_distance, person1: member2.person, person2: member1.person)
        expect(d.overlap_dates).to eq []
      end
    end
  end
end
