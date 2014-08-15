require 'spec_helper'

describe MemberDistance, :type => :model do
  # Just making sure we're not loading any fixtures
  it { expect(Member.all).to be_empty }

  describe "calculating cache values" do
    let(:membera) { Member.create(first_name: "Member", last_name: "A", gid: "A", source_gid: "A",
      title: "", constituency: "foo", party: "Party", house: "House") }
    let(:memberb) { Member.create(first_name: "Member", last_name: "B", gid: "B", source_gid: "B",
      title: "", constituency: "bar", party: "Party", house: "House") }

    it { expect(MemberDistance.calculate_nvotessame(membera, memberb)).to eq 0 }

    context "with votes in one division" do
      let(:division) { Division.create(division_name: "1", division_date: Date.new(2000,1,1),
      division_number: 1, house: "House", source_url: "", debate_url: "", motion: "", notes: "",
      source_gid: "", debate_gid: "") }

      it "votes absent aye" do
        memberb.votes.create(division: division, vote: "aye")
        expect(MemberDistance.calculate_nvotessame(membera, memberb)).to eq 0
      end

      it "votes aye aye" do
        membera.votes.create(division: division, vote: "aye")
        memberb.votes.create(division: division, vote: "aye")
        expect(MemberDistance.calculate_nvotessame(membera, memberb)).to eq 1
      end

      it "votes aye no" do
        membera.votes.create(division: division, vote: "aye")
        memberb.votes.create(division: division, vote: "no")
        expect(MemberDistance.calculate_nvotessame(membera, memberb)).to eq 0
      end

      it "votes aye tellaye" do
        membera.votes.create(division: division, vote: "aye")
        memberb.votes.create(division: division, vote: "tellaye")
        expect(MemberDistance.calculate_nvotessame(membera, memberb)).to eq 1
      end

      it "votes aye tellno" do
        membera.votes.create(division: division, vote: "aye")
        memberb.votes.create(division: division, vote: "tellno")
        expect(MemberDistance.calculate_nvotessame(membera, memberb)).to eq 0
      end

      it "votes no tellno" do
        membera.votes.create(division: division, vote: "no")
        memberb.votes.create(division: division, vote: "tellno")
        expect(MemberDistance.calculate_nvotessame(membera, memberb)).to eq 1
      end
    end

    context "with votes on five divisions" do
      before :each do
        # Member A: 1 aye,    2 aye, 3 aye, 4 no, 5 absent
        # Member B: 1 absent, 2 aye, 3 no,  4 no, 5 no
        division1 = Division.create(division_name: "1", division_date: Date.new(2000,1,1),
        division_number: 1, house: "House", source_url: "", debate_url: "", motion: "", notes: "",
        source_gid: "", debate_gid: "")
        division2 = Division.create(division_name: "2", division_date: Date.new(2000,1,1),
        division_number: 2, house: "House", source_url: "", debate_url: "", motion: "", notes: "",
        source_gid: "", debate_gid: "")
        division3 = Division.create(division_name: "3", division_date: Date.new(2000,1,1),
        division_number: 3, house: "House", source_url: "", debate_url: "", motion: "", notes: "",
        source_gid: "", debate_gid: "")
        division4 = Division.create(division_name: "4", division_date: Date.new(2000,1,1),
        division_number: 4, house: "House", source_url: "", debate_url: "", motion: "", notes: "",
        source_gid: "", debate_gid: "")
        division5 = Division.create(division_name: "5", division_date: Date.new(2000,1,1),
        division_number: 5, house: "House", source_url: "", debate_url: "", motion: "", notes: "",
        source_gid: "", debate_gid: "")
        membera.votes.create(division: division1, vote: "aye")
        membera.votes.create(division: division2, vote: "aye")
        membera.votes.create(division: division3, vote: "aye")
        membera.votes.create(division: division4, vote: "no")
        memberb.votes.create(division: division2, vote: "aye")
        memberb.votes.create(division: division3, vote: "no")
        memberb.votes.create(division: division4, vote: "no")
        memberb.votes.create(division: division5, vote: "no")
      end

      it { expect(MemberDistance.calculate_nvotessame(membera, memberb)).to eq 2 }
    end
  end
end
