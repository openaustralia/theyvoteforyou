require 'spec_helper'

describe MemberInfo, type: :model do
  describe "counts" do
    let(:membera) { Member.create(id: 1, first_name: "Member", last_name: "A", gid: "", source_gid: "",
      title: "", constituency: "", party: "A", house: "commons",
      entered_house: Date.new(1999,1,1), left_house: Date.new(2001,1,1)) }
    let(:memberb) { Member.create(id: 2, first_name: "Member", last_name: "B", gid: "", source_gid: "",
      title: "", constituency: "", party: "A", house: "commons",
      entered_house: Date.new(1999,1,1), left_house: Date.new(2001,1,1)) }

    let(:division1) { Division.create(name: "1", date: Date.new(2000,1,1),
    number: 1, house: "commons", source_url: "", debate_url: "", motion: "",
    source_gid: "", debate_gid: "") }
    let(:division2) { Division.create(name: "2", date: Date.new(2000,1,1),
    number: 2, house: "commons", source_url: "", debate_url: "", motion: "",
    source_gid: "", debate_gid: "") }
    # This division neither of the members could have voted on
    let(:division3) { Division.create(name: "3", date: Date.new(2002,1,1),
    number: 1, house: "commons", source_url: "", debate_url: "", motion: "",
    source_gid: "", debate_gid: "") }

    before :each do
      # vote counts shouldn't be used for anything. So, setting to 0
      Whip.create(division: division1, party: "A", whip_guess: "no", aye_votes: 0, aye_tells: 0,
        no_votes: 0, no_tells: 0, both_votes: 0, abstention_votes: 0, possible_votes: 0)
      Whip.create(division: division2, party: "A", whip_guess: "aye", aye_votes: 0, aye_tells: 0,
        no_votes: 0, no_tells: 0, both_votes: 0, abstention_votes: 0, possible_votes: 0)
      Whip.create(division: division3, party: "A", whip_guess: "aye", aye_votes: 0, aye_tells: 0,
        no_votes: 0, no_tells: 0, both_votes: 0, abstention_votes: 0, possible_votes: 0)
    end

    it do
      Vote.create(division: division1, member: membera, vote: "no")
      Vote.create(division: division1, member: memberb, vote: "no", teller: true)
      Vote.create(division: division2, member: membera, vote: "aye")
      expect(MemberInfo.all_rebellion_counts).to eq ({})
      expect(MemberInfo.all_tells_counts).to eq({2 => 1})
      expect(MemberInfo.all_votes_attended_counts).to eq({1 => 2, 2 => 1})
      expect(MemberInfo.all_ayes_counts).to eq({1 => 1})
      expect(MemberInfo.all_noes_counts).to eq({1 => 1, 2 => 1})
      expect(MemberInfo.all_aye_majority_counts).to eq({1 => 0, 2 => -1})
      expect(MemberInfo.all_votes_possible_counts).to eq({1 => 2, 2 => 2})
    end

    it do
      Vote.create(division: division1, member: membera, vote: "aye", teller: true)
      Vote.create(division: division1, member: memberb, vote: "aye")
      expect(MemberInfo.all_rebellion_counts).to eq ({1 => 1, 2 => 1})
      expect(MemberInfo.all_tells_counts).to eq({1 => 1})
      expect(MemberInfo.all_votes_attended_counts).to eq({1 => 1, 2 => 1})
      expect(MemberInfo.all_ayes_counts).to eq({1 => 1, 2 => 1})
      expect(MemberInfo.all_noes_counts).to eq({})
      expect(MemberInfo.all_aye_majority_counts).to eq({1 => 1, 2 => 1})
      expect(MemberInfo.all_votes_possible_counts).to eq({1 => 2, 2 => 2})
    end
  end
end
