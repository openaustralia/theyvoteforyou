# frozen_string_literal: true

require "spec_helper"

describe Whip, type: :model do
  describe "#free_vote?" do
    it do
      division = Division.new(house: "senate", date: "2006-02-09", number: 3)
      expect(described_class.new(division: division, party: "Liberal Party")).to be_free_vote
    end

    it do
      division = Division.new(house: "senate", date: "2001-01-01", number: 1)
      whip = described_class.new(division: division, party: "Liberal Party")
      expect(whip).not_to be_free_vote
    end
  end

  describe ".calc_whip_guess" do
    context "when no abstentions" do
      it { expect(described_class.calc_whip_guess(10, 5, 0)).to eq "aye" }
      it { expect(described_class.calc_whip_guess(5, 10, 0)).to eq "no" }
      it { expect(described_class.calc_whip_guess(5, 5, 0)).to eq "unknown" }
    end

    context "when 10 abstentions" do
      it { expect(described_class.calc_whip_guess(5, 5, 10)).to eq "abstention" }
      it { expect(described_class.calc_whip_guess(5, 10, 10)).to eq "unknown" }
      it { expect(described_class.calc_whip_guess(5, 15, 10)).to eq "no" }
      it { expect(described_class.calc_whip_guess(10, 5, 10)).to eq "unknown" }
      it { expect(described_class.calc_whip_guess(10, 10, 10)).to eq "unknown" }
      it { expect(described_class.calc_whip_guess(10, 15, 10)).to eq "no" }
      it { expect(described_class.calc_whip_guess(15, 5, 10)).to eq "aye" }
      it { expect(described_class.calc_whip_guess(15, 10, 10)).to eq "aye" }
      it { expect(described_class.calc_whip_guess(15, 15, 10)).to eq "unknown" }
    end
  end

  describe ".calc_all_votes_per_party" do
    before do
      member1
      member2
      member3
      member4
      member5
    end

    let(:division) { Division.create(id: 1, date: Date.new(2000, 1, 1), number: 1, house: "commons", name: "Foo", source_url: "", debate_url: "", motion: "", debate_gid: "") }
    let(:person1) { create(:person) }
    let(:person2) { create(:person) }
    let(:person3) { create(:person) }
    let(:person4) { create(:person) }
    let(:person5) { create(:person) }
    let(:member1) do
      Member.create!(id: 1, title: "", first_name: "Member", last_name: "1", party: "A",
                     house: "commons", gid: "", source_gid: "", constituency: "A",
                     entered_house: Date.new(1999, 1, 1), left_house: Date.new(2001, 1, 1),
                     person: person1)
    end
    let(:member2) do
      Member.create!(id: 2, title: "", first_name: "Member", last_name: "2", party: "B",
                     house: "commons", gid: "", source_gid: "", constituency: "B",
                     entered_house: Date.new(1999, 1, 1), left_house: Date.new(2001, 1, 1),
                     person: person2)
    end
    let(:member3) do
      Member.create!(id: 3, title: "", first_name: "Member", last_name: "3", party: "B",
                     house: "commons", gid: "", source_gid: "", constituency: "C",
                     entered_house: Date.new(1999, 1, 1), left_house: Date.new(2001, 1, 1),
                     person: person3)
    end
    # This member doesn't vote but could
    let(:member4) do
      Member.create!(id: 4, title: "", first_name: "Member", last_name: "4", party: "B",
                     house: "commons", gid: "", source_gid: "", constituency: "D",
                     entered_house: Date.new(1999, 1, 1), left_house: Date.new(2001, 1, 1),
                     person: person4)
    end
    # This member couldn't vote in the division
    let(:member5) do
      Member.create!(id: 5, title: "", first_name: "Member", last_name: "5", party: "B",
                     house: "commons", gid: "", source_gid: "", constituency: "E",
                     entered_house: Date.new(1998, 1, 1), left_house: Date.new(1999, 1, 1),
                     person: person5)
    end

    context "when one aye vote in party A" do
      before do
        division.votes.create(member: member1, vote: "aye")
      end

      it { expect(described_class.calc_all_votes_per_party).to eq([1, "A", "aye", 0] => 1) }
      it { expect(described_class.calc_all_votes_per_party2).to eq([1, "A"] => { ["aye", 0] => 1 }) }

      it do
        described_class.update_all!
        expect(described_class.all.count).to eq 2
        w = described_class.find_by(division: division, party: "A")
        expect(w.aye_votes).to eq 1
        expect(w.aye_tells).to eq 0
        expect(w.no_votes).to eq 0
        expect(w.no_tells).to eq 0
        expect(w.both_votes).to eq 0
        expect(w.abstention_votes).to eq 0
        expect(w.possible_votes).to eq 1
        expect(w.whip_guess).to eq "aye"
        w = described_class.find_by(division: division, party: "B")
        expect(w.aye_votes).to eq 0
        expect(w.aye_tells).to eq 0
        expect(w.no_votes).to eq 0
        expect(w.no_tells).to eq 0
        expect(w.both_votes).to eq 0
        expect(w.abstention_votes).to eq 0
        expect(w.possible_votes).to eq 3
        expect(w.whip_guess).to eq "unknown"
      end

      context "when free vote" do
        it do
          # TODO: get rid of use of any_instance. It's a code smell.
          # rubocop:disable RSpec/AnyInstance
          allow_any_instance_of(described_class).to receive(:free_vote?).and_return(true)
          # rubocop:enable RSpec/AnyInstance
          described_class.update_all!
          w = described_class.find_by(division: division, party: "A")
          expect(w.whip_guess).to eq "none"
        end
      end

      context "when whipless party vote" do
        it do
          # TODO: get rid of use of any_instance. It's a code smell.
          # rubocop:disable RSpec/AnyInstance
          allow_any_instance_of(described_class).to receive(:whipless?).and_return(true)
          # rubocop:enable RSpec/AnyInstance
          described_class.update_all!
          w = described_class.find_by(division: division, party: "A")
          expect(w.whip_guess).to eq "none"
        end
      end

      context "when 2 aye votes in party B" do
        before do
          division.votes.create(member: member2, vote: "aye")
          division.votes.create(member: member3, vote: "aye")
        end

        it { expect(described_class.calc_all_votes_per_party).to eq([1, "A", "aye", 0] => 1, [1, "B", "aye", 0] => 2) }
        it { expect(described_class.calc_all_votes_per_party2).to eq([1, "A"] => { ["aye", 0] => 1 }, [1, "B"] => { ["aye", 0] => 2 }) }

        it do
          described_class.update_all!
          expect(described_class.all.count).to eq 2
          w = described_class.find_by(division: division, party: "A")
          expect(w.aye_votes).to eq 1
          expect(w.aye_tells).to eq 0
          expect(w.no_votes).to eq 0
          expect(w.no_tells).to eq 0
          expect(w.both_votes).to eq 0
          expect(w.abstention_votes).to eq 0
          expect(w.possible_votes).to eq 1
          expect(w.whip_guess).to eq "aye"
          w = described_class.find_by(division: division, party: "B")
          expect(w.aye_votes).to eq 2
          expect(w.aye_tells).to eq 0
          expect(w.no_votes).to eq 0
          expect(w.no_tells).to eq 0
          expect(w.both_votes).to eq 0
          expect(w.abstention_votes).to eq 0
          expect(w.possible_votes).to eq 3
          expect(w.whip_guess).to eq "aye"
        end
      end

      context "when 1 aye vote and 1 no vote in party B" do
        before do
          division.votes.create(member: member2, vote: "aye")
          division.votes.create(member: member3, vote: "no")
        end

        it { expect(described_class.calc_all_votes_per_party).to eq([1, "A", "aye", 0] => 1, [1, "B", "aye", 0] => 1, [1, "B", "no", 0] => 1) }
        it { expect(described_class.calc_all_votes_per_party2).to eq([1, "A"] => { ["aye", 0] => 1 }, [1, "B"] => { ["aye", 0] => 1, ["no", 0] => 1 }) }

        it do
          described_class.update_all!
          expect(described_class.all.count).to eq 2
          w = described_class.find_by(division: division, party: "A")
          expect(w.aye_votes).to eq 1
          expect(w.aye_tells).to eq 0
          expect(w.no_votes).to eq 0
          expect(w.no_tells).to eq 0
          expect(w.both_votes).to eq 0
          expect(w.abstention_votes).to eq 0
          expect(w.possible_votes).to eq 1
          expect(w.whip_guess).to eq "aye"
          w = described_class.find_by(division: division, party: "B")
          expect(w.aye_votes).to eq 1
          expect(w.aye_tells).to eq 0
          expect(w.no_votes).to eq 1
          expect(w.no_tells).to eq 0
          expect(w.both_votes).to eq 0
          expect(w.abstention_votes).to eq 0
          expect(w.possible_votes).to eq 3
          expect(w.whip_guess).to eq "unknown"
        end
      end
    end
  end
end
