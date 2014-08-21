require 'spec_helper'

describe Member, :type => :model do
  describe ".all_rebellion_counts" do
    let(:membera) { Member.create(mp_id: 1, first_name: "Member", last_name: "A", gid: "", source_gid: "",
      title: "", constituency: "", party: "A", house: "commons",
      entered_house: Date.new(1999,1,1), left_house: Date.new(2001,1,1)) }
    let(:memberb) { Member.create(mp_id: 2, first_name: "Member", last_name: "B", gid: "", source_gid: "",
      title: "", constituency: "", party: "A", house: "commons",
      entered_house: Date.new(1999,1,1), left_house: Date.new(2001,1,1)) }

    let(:division) { Division.create(division_name: "1", division_date: Date.new(2000,1,1),
    division_number: 1, house: "commons", source_url: "", debate_url: "", motion: "", notes: "",
    source_gid: "", debate_gid: "") }

    before :each do
      # vote counts shouldn't be used for anything. So, setting to 0
      Whip.create(division: division, party: "A", whip_guess: "no", aye_votes: 0, aye_tells: 0,
        no_votes: 0, no_tells: 0, both_votes: 0, abstention_votes: 0, possible_votes: 0)
    end

    it do
      Vote.create(division: division, member: membera, vote: "no")
      Vote.create(division: division, member: memberb, vote: "tellno")
      expect(Member.all_rebellion_counts).to eq ({})
      expect(Member.all_tells_counts).to eq({2 => 1})
      expect(Member.all_votes_attended_counts).to eq({1 => 1, 2 => 1})
    end

    it do
      Vote.create(division: division, member: membera, vote: "tellaye")
      Vote.create(division: division, member: memberb, vote: "aye")
      expect(Member.all_rebellion_counts).to eq ({1 => 1, 2 => 1})
      expect(Member.all_tells_counts).to eq({1 => 1})
      expect(Member.all_votes_attended_counts).to eq({1 => 1, 2 => 1})
    end
  end
end
