require 'spec_helper'

describe Whip, type: :model do
  # TODO Figure out why we need to do this horrible hack to remove the fixtures
  # we shouldn't have them loaded
  before :each do
    Member.delete_all
    Division.delete_all
    Vote.delete_all
    Whip.delete_all
  end

  describe "#free_vote?" do
    it do
      division = Division.new(house: 'senate', date: '2006-02-09', number: 3)
      expect(Whip.new(division: division, party: 'Liberal Party').free_vote?).to be_truthy
    end

    it do
      division = Division.new(house: 'senate', date: '2001-01-01', number: 1)
      whip = Whip.new(division: division, party: 'Liberal Party')
      expect(whip.free_vote?).to be_falsy
    end
  end

  describe ".calc_whip_guess" do
    context "no abstentions" do
      it { expect(Whip.calc_whip_guess(10, 5, 0)).to eq "aye" }
      it { expect(Whip.calc_whip_guess(5, 10, 0)).to eq "no" }
      it { expect(Whip.calc_whip_guess(5, 5, 0)).to eq "unknown" }
    end

    context "10 abstentions" do
      it { expect(Whip.calc_whip_guess(5, 5, 10)).to eq "abstention" }
      it { expect(Whip.calc_whip_guess(5, 10, 10)).to eq "unknown" }
      it { expect(Whip.calc_whip_guess(5, 15, 10)).to eq "no" }
      it { expect(Whip.calc_whip_guess(10, 5, 10)).to eq "unknown"}
      it { expect(Whip.calc_whip_guess(10, 10, 10)).to eq "unknown" }
      it { expect(Whip.calc_whip_guess(10, 15, 10)).to eq "no" }
      it { expect(Whip.calc_whip_guess(15, 5, 10)).to eq "aye" }
      it { expect(Whip.calc_whip_guess(15, 10, 10)).to eq "aye" }
      it { expect(Whip.calc_whip_guess(15, 15, 10)).to eq "unknown" }
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

    let(:division) { Division.create(id: 1, date: Date.new(2000,1,1), number: 1, house: "commons", name: "Foo", source_url: "", debate_url: "", motion: "", source_gid: "", debate_gid: "") }
    let(:member1) { Member.create(id: 1, title: "", first_name: "Member", last_name: "1", party: "A",
      house: "commons", gid: "", source_gid: "",  constituency: "A",
      entered_house: Date.new(1999,1,1), left_house: Date.new(2001,1,1)) }
    let(:member2) { Member.create(id: 2, title: "", first_name: "Member", last_name: "2", party: "B",
      house: "commons", gid: "", source_gid: "",  constituency: "B",
      entered_house: Date.new(1999,1,1), left_house: Date.new(2001,1,1)) }
    let(:member3) { Member.create(id: 3, title: "", first_name: "Member", last_name: "3", party: "B",
      house: "commons", gid: "", source_gid: "",  constituency: "C",
      entered_house: Date.new(1999,1,1), left_house: Date.new(2001,1,1)) }
    # This member doesn't vote but could
    let(:member4) { Member.create(id: 4, title: "", first_name: "Member", last_name: "4", party: "B",
      house: "commons", gid: "", source_gid: "",  constituency: "D",
      entered_house: Date.new(1999,1,1), left_house: Date.new(2001,1,1)) }
    # This member couldn't vote in the division
    let(:member5) { Member.create(id: 5, title: "", first_name: "Member", last_name: "5", party: "B",
      house: "commons", gid: "", source_gid: "",  constituency: "E",
      entered_house: Date.new(1998,1,1), left_house: Date.new(1999,1,1)) }

    context "one aye vote in party A" do
      before :each do
        division.votes.create(member: member1, vote: "aye")
      end

      it { expect(Whip.calc_all_votes_per_party).to eq([1, "A", "aye", 0] => 1)}
      it { expect(Whip.calc_all_votes_per_party2).to eq([1, "A"] => {["aye", 0] => 1})}
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
        expect(w.whip_guess).to eq "aye"
        w = Whip.find_by(division: division, party: "B")
        expect(w.aye_votes).to eq 0
        expect(w.aye_tells).to eq 0
        expect(w.no_votes).to eq 0
        expect(w.no_tells).to eq 0
        expect(w.both_votes).to eq 0
        expect(w.abstention_votes).to eq 0
        expect(w.possible_votes).to eq 3
        expect(w.whip_guess).to eq "unknown"
      end

      context "free vote" do
        it do
          # TODO get rid of use of any_instance. It's a code smell.
          allow_any_instance_of(Whip).to receive(:free_vote?).and_return(true)
          Whip.update_all!
          w = Whip.find_by(division: division, party: "A")
          expect(w.whip_guess).to eq "none"
        end
      end

      context "whipless party vote" do
        it do
          allow_any_instance_of(Whip).to receive(:whipless?).and_return(true)
          Whip.update_all!
          w = Whip.find_by(division: division, party: "A")
          expect(w.whip_guess).to eq "none"
        end
      end

      context "and 2 aye votes in party B" do
        before :each do
          division.votes.create(member: member2, vote: "aye")
          division.votes.create(member: member3, vote: "aye")
        end

        it { expect(Whip.calc_all_votes_per_party).to eq([1, "A", "aye", 0] => 1, [1, "B", "aye", 0] => 2)}
        it { expect(Whip.calc_all_votes_per_party2).to eq([1, "A"] => {["aye", 0] => 1}, [1, "B"] => {["aye", 0] => 2})}
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
          expect(w.whip_guess).to eq "aye"
          w = Whip.find_by(division: division, party: "B")
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

      context "and 1 aye vote and 1 no vote in party B" do
        before :each do
          division.votes.create(member: member2, vote: "aye")
          division.votes.create(member: member3, vote: "no")
        end

        it { expect(Whip.calc_all_votes_per_party).to eq([1, "A", "aye", 0] => 1, [1, "B", "aye", 0] => 1, [1, "B", "no", 0] => 1) }
        it { expect(Whip.calc_all_votes_per_party2).to eq([1, "A"] => {["aye", 0] => 1}, [1, "B"] => {["aye", 0] => 1, ["no", 0] => 1}) }
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
          expect(w.whip_guess).to eq "aye"
          w = Whip.find_by(division: division, party: "B")
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
