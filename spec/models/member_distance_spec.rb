require 'spec_helper'

describe MemberDistance, :type => :model do
  # Just making sure we're not loading any fixtures
  it { expect(Member.all).to be_empty }

  describe "calculating cache values" do
    let(:membera) { Member.create(mp_id: 1, first_name: "Member", last_name: "A", gid: "A", source_gid: "A",
      title: "", constituency: "foo", party: "Party", house: "commons") }
    let(:memberb) { Member.create(mp_id: 2, first_name: "Member", last_name: "B", gid: "B", source_gid: "B",
      title: "", constituency: "bar", party: "Party", house: "commons") }

    it { expect(MemberDistance.calculate_nvotessame(membera, memberb)).to eq 0 }
    it { expect(MemberDistance.calculate_nvotesdiffer(membera, memberb)).to eq 0}
    it { expect(MemberDistance.calculate_nvotesabsent(membera, memberb)).to eq 0}

    context "with votes in one division" do
      let(:division) { Division.create(division_name: "1", division_date: Date.new(2000,1,1),
      division_number: 1, house: "commons", source_url: "", debate_url: "", motion: "", notes: "",
      source_gid: "", debate_gid: "") }

      def check_vote_combination(vote1, vote2, same, differ, absent)
        membera.votes.create(division: division, vote: vote1) unless vote1 == "absent"
        memberb.votes.create(division: division, vote: vote2) unless vote2 == "absent"
        expect(MemberDistance.calculate_nvotessame(membera, memberb)).to eq same
        expect(MemberDistance.calculate_nvotesdiffer(membera, memberb)).to eq differ
        expect(MemberDistance.calculate_nvotesabsent(membera, memberb)).to eq absent
      end

      it { check_vote_combination("absent",     "absent", 0, 0, 0) }
      it { check_vote_combination("absent",     "aye",    0, 0, 1) }
      it { check_vote_combination("absent",     "no",     0, 0, 1) }
      it { check_vote_combination("absent",     "tellaye",0, 0, 1) }
      it { check_vote_combination("absent",     "tellno", 0, 0, 1) }
      it { check_vote_combination("aye",        "absent", 0, 0, 1) }
      it { check_vote_combination("aye",        "aye",    1, 0, 0) }
      it { check_vote_combination("aye",        "no",     0, 1, 0) }
      it { check_vote_combination("aye",        "tellaye",1, 0, 0) }
      it { check_vote_combination("aye",        "tellno", 0, 1, 0) }
      it { check_vote_combination("no",         "absent", 0, 0, 1) }
      it { check_vote_combination("no",         "aye",    0, 1, 0) }
      it { check_vote_combination("no",         "no",     1, 0, 0) }
      it { check_vote_combination("no",         "tellaye",0, 1, 0) }
      it { check_vote_combination("no",         "tellno", 1, 0, 0) }
      it { check_vote_combination("tellaye",    "absent", 0, 0, 1) }
      it { check_vote_combination("tellaye",    "aye",    1, 0, 0) }
      it { check_vote_combination("tellaye",    "no",     0, 1, 0) }
      it { check_vote_combination("tellaye",    "tellaye",1, 0, 0) }
      it { check_vote_combination("tellaye",    "tellno", 0, 1, 0) }
      it { check_vote_combination("tellno",     "absent", 0, 0, 1) }
      it { check_vote_combination("tellno",     "aye",    0, 1, 0) }
      it { check_vote_combination("tellno",     "no",     1, 0, 0) }
      it { check_vote_combination("tellno",     "tellaye",0, 1, 0) }
      it { check_vote_combination("tellno",     "tellno", 1, 0, 0) }

    end

    context "with votes on five divisions" do
      before :each do
        # Member A: 1 aye,    2 aye,     3 aye, 4 tellno, 5 absent
        # Member B: 1 absent, 2 tellaye, 3 no,  4 no,     5 no
        division1 = Division.create(division_name: "1", division_date: Date.new(2000,1,1),
        division_number: 1, house: "commons", source_url: "", debate_url: "", motion: "", notes: "",
        source_gid: "", debate_gid: "")
        division2 = Division.create(division_name: "2", division_date: Date.new(2000,1,1),
        division_number: 2, house: "commons", source_url: "", debate_url: "", motion: "", notes: "",
        source_gid: "", debate_gid: "")
        division3 = Division.create(division_name: "3", division_date: Date.new(2000,1,1),
        division_number: 3, house: "commons", source_url: "", debate_url: "", motion: "", notes: "",
        source_gid: "", debate_gid: "")
        division4 = Division.create(division_name: "4", division_date: Date.new(2000,1,1),
        division_number: 4, house: "commons", source_url: "", debate_url: "", motion: "", notes: "",
        source_gid: "", debate_gid: "")
        division5 = Division.create(division_name: "5", division_date: Date.new(2000,1,1),
        division_number: 5, house: "commons", source_url: "", debate_url: "", motion: "", notes: "",
        source_gid: "", debate_gid: "")
        membera.votes.create(division: division1, vote: "aye")
        membera.votes.create(division: division2, vote: "aye")
        membera.votes.create(division: division3, vote: "aye")
        membera.votes.create(division: division4, vote: "tellno")
        memberb.votes.create(division: division2, vote: "tellaye")
        memberb.votes.create(division: division3, vote: "no")
        memberb.votes.create(division: division4, vote: "no")
        memberb.votes.create(division: division5, vote: "no")
      end

      it { expect(MemberDistance.calculate_nvotessame(membera, memberb)).to eq 2 }
      it { expect(MemberDistance.calculate_nvotesdiffer(membera, memberb)).to eq 1 }
      it { expect(MemberDistance.calculate_nvotesabsent(membera, memberb)).to eq 2 }

      it "should calculate the cache on creating" do
        expect(Distance).to receive(:distance_a).with(2, 1, 2).and_return(0.1)
        expect(Distance).to receive(:distance_b).with(2, 1).and_return(0.2)
        m = MemberDistance.create(member1: membera, member2: memberb)
        # We can't call m.reload because we don't have a primary key. So, do this instead
        m = MemberDistance.first
        expect(m.nvotessame).to eq 2
        expect(m.nvotesdiffer).to eq 1
        expect(m.nvotesabsent).to eq 2
        expect(m.distance_a).to eq 0.1
        expect(m.distance_b).to eq 0.2
      end
    end
  end
end
