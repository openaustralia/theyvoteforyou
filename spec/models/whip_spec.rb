require 'spec_helper'

describe Whip, :type => :model do
  # TODO Figure out why we need to do this horrible hack to remove the fixtures
  # we shouldn't have them loaded
  before :each do
    Member.delete_all
    Division.delete_all
    Vote.delete_all
    Whip.delete_all
  end

  describe '#whip_guess_majority' do
    it 'whip guess is aye and noes are in the majority' do
      allow(subject).to receive(:whip_guess).and_return("aye")
      allow(subject).to receive(:noes_in_majority?).and_return(true)
      expect(subject.whip_guess_majority).to eq('minority')
    end
  end

  describe ".calc_all_votes_per_party" do
    before :each do
      member1
      member2
      member3
      member4
      member5
    end

    let(:division) { Division.create(division_id: 1, division_date: Date.new(2000,1,1), division_number: 1, house: "commons", division_name: "Foo", source_url: "", debate_url: "", motion: "", notes: "", source_gid: "", debate_gid: "") }
    let(:member1) { Member.create(mp_id: 1, title: "", first_name: "Member", last_name: "1", party: "A",
      house: "commons", gid: "", source_gid: "",  constituency: "A",
      entered_house: Date.new(1999,1,1), left_house: Date.new(2001,1,1)) }
    let(:member2) { Member.create(mp_id: 2, title: "", first_name: "Member", last_name: "2", party: "B",
      house: "commons", gid: "", source_gid: "",  constituency: "B",
      entered_house: Date.new(1999,1,1), left_house: Date.new(2001,1,1)) }
    let(:member3) { Member.create(mp_id: 3, title: "", first_name: "Member", last_name: "3", party: "B",
      house: "commons", gid: "", source_gid: "",  constituency: "C",
      entered_house: Date.new(1999,1,1), left_house: Date.new(2001,1,1)) }
    # This member doesn't vote but could
    let(:member4) { Member.create(mp_id: 4, title: "", first_name: "Member", last_name: "4", party: "B",
      house: "commons", gid: "", source_gid: "",  constituency: "D",
      entered_house: Date.new(1999,1,1), left_house: Date.new(2001,1,1)) }
    # This member couldn't vote in the division
    let(:member5) { Member.create(mp_id: 5, title: "", first_name: "Member", last_name: "5", party: "B",
      house: "commons", gid: "", source_gid: "",  constituency: "E",
      entered_house: Date.new(1998,1,1), left_house: Date.new(1999,1,1)) }

    context "one aye vote in party A" do
      before :each do
        division.votes.create(member: member1, vote: "aye")
      end

      it { expect(Whip.calc_all_votes_per_party).to eq([1, "A", "aye"] => 1)}
      it { expect(Whip.calc_all_votes_per_party2).to eq([1, "A"] => {"aye" => 1})}
      it do
        Whip.update_all!
        expect(Whip.all.count).to eq 1
        w = Whip.find_by(division: division, party: "A")
        expect(w.aye_votes).to eq 1
        expect(w.aye_tells).to eq 0
        expect(w.no_votes).to eq 0
        expect(w.no_tells).to eq 0
        expect(w.both_votes).to eq 0
        expect(w.abstention_votes).to eq 0
        expect(w.possible_votes).to eq 1
      end

      context "and 2 aye votes in party B" do
        before :each do
          division.votes.create(member: member2, vote: "aye")
          division.votes.create(member: member3, vote: "aye")
        end

        it { expect(Whip.calc_all_votes_per_party).to eq([1, "A", "aye"] => 1, [1, "B", "aye"] => 2)}
        it { expect(Whip.calc_all_votes_per_party2).to eq([1, "A"] => {"aye" => 1}, [1, "B"] => {"aye" => 2})}
        it do
          Whip.update_all!
          expect(Whip.all.count).to eq 2
          w = Whip.find_by(division: division, party: "A")
          expect(w.aye_votes).to eq 1
          expect(w.aye_tells).to eq 0
          expect(w.no_votes).to eq 0
          expect(w.no_tells).to eq 0
          expect(w.both_votes).to eq 0
          expect(w.abstention_votes).to eq 0
          expect(w.possible_votes).to eq 1
          w = Whip.find_by(division: division, party: "B")
          expect(w.aye_votes).to eq 2
          expect(w.aye_tells).to eq 0
          expect(w.no_votes).to eq 0
          expect(w.no_tells).to eq 0
          expect(w.both_votes).to eq 0
          expect(w.abstention_votes).to eq 0
          expect(w.possible_votes).to eq 3
        end
      end

      context "and 1 aye vote and 1 no vote in party B" do
        before :each do
          division.votes.create(member: member2, vote: "aye")
          division.votes.create(member: member3, vote: "no")
        end

        it { expect(Whip.calc_all_votes_per_party).to eq([1, "A", "aye"] => 1, [1, "B", "aye"] => 1, [1, "B", "no"] => 1) }
        it { expect(Whip.calc_all_votes_per_party2).to eq([1, "A"] => {"aye" => 1}, [1, "B"] => {"aye" => 1, "no" => 1}) }
        it do
          Whip.update_all!
          expect(Whip.all.count).to eq 2
          w = Whip.find_by(division: division, party: "A")
          expect(w.aye_votes).to eq 1
          expect(w.aye_tells).to eq 0
          expect(w.no_votes).to eq 0
          expect(w.no_tells).to eq 0
          expect(w.both_votes).to eq 0
          expect(w.abstention_votes).to eq 0
          expect(w.possible_votes).to eq 1
          w = Whip.find_by(division: division, party: "B")
          expect(w.aye_votes).to eq 1
          expect(w.aye_tells).to eq 0
          expect(w.no_votes).to eq 1
          expect(w.no_tells).to eq 0
          expect(w.both_votes).to eq 0
          expect(w.abstention_votes).to eq 0
          expect(w.possible_votes).to eq 3
        end
      end
    end
  end
end
