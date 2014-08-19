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

  describe ".calc_all_aye_votes_per_party" do
    let(:division) { Division.create(division_id: 1, division_date: Date.new(2000,1,1), division_number: 1, house: "commons", division_name: "Foo", source_url: "", debate_url: "", motion: "", notes: "", source_gid: "", debate_gid: "") }
    let(:member1) { Member.create(mp_id: 1, title: "", first_name: "Member", last_name: "1", party: "A",
      house: "commons", gid: "", source_gid: "",  constituency: "A") }

    context "one aye vote in party A" do
      before :each do
        division.votes.create(member: member1, vote: "aye")
      end

      it { expect(Whip.calc_all_aye_votes_per_party).to eq([1, "A"] => 1) }
    end
  end
end
