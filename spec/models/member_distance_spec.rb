require 'spec_helper'

describe MemberDistance, type: :model do
  # TODO Figure out why we need to do this horrible hack to remove the fixtures
  # we shouldn't have them loaded
  before :each do
    Member.delete_all
    MemberDistance.delete_all
    Division.delete_all
    Vote.delete_all
  end

  # Just making sure we're not loading any fixtures
  it { expect(Member.all).to be_empty }

  describe "calculating cache values" do
    let(:membera) { Member.create(id: 1, first_name: "Member", last_name: "A", gid: "A", source_gid: "A",
      title: "", constituency: "foo", party: "Party", house: "commons",
      entered_house: Date.new(1990,1,1), left_house: Date.new(2001,1,1)) }
    let(:memberb) { Member.create(id: 2, first_name: "Member", last_name: "B", gid: "B", source_gid: "B",
      title: "", constituency: "bar", party: "Party", house: "commons",
      entered_house: Date.new(1999,1,1), left_house: Date.new(2010,1,1)) }

    it { expect(MemberDistance.calculate_nvotessame(membera.id, memberb.id)).to eq 0 }
    it { expect(MemberDistance.calculate_nvotesdiffer(membera.id, memberb.id)).to eq 0}
    it { expect(MemberDistance.calculate_nvotesabsent(membera.id, membera.entered_house, membera.left_house, memberb.id, memberb.entered_house, memberb.left_house)).to eq 0}

    def check_vote_combination(vote1, teller1, vote2, teller2, same, differ, absent)
      membera.votes.create(division: division, vote: vote1, teller: teller1) unless vote1 == "absent"
      memberb.votes.create(division: division, vote: vote2, teller: teller2) unless vote2 == "absent"
      expect(MemberDistance.calculate_nvotessame(membera.id, memberb.id)).to eq same
      expect(MemberDistance.calculate_nvotesdiffer(membera.id, memberb.id)).to eq differ
      expect(MemberDistance.calculate_nvotesabsent(membera.id, membera.entered_house, membera.left_house, memberb.id, memberb.entered_house, memberb.left_house)).to eq absent
    end

    context "with votes in one division that only member A could vote on" do
      let(:division) { Division.create(name: "1", date: Date.new(1995,1,1),
      number: 1, house: "commons", source_url: "", debate_url: "", motion: "",
      source_gid: "", debate_gid: "") }

      it { check_vote_combination("absent", false, "absent", false, 0, 0, 0) }
      it { check_vote_combination("aye",    false, "absent", false, 0, 0, 0) }
      it { check_vote_combination("no",     false, "absent", false, 0, 0, 0) }
      it { check_vote_combination("aye",    true,  "absent", false, 0, 0, 0) }
      it { check_vote_combination("no",     true,  "absent", false, 0, 0, 0) }
    end

    context "with votes in one division that both members could vote on" do
      let(:division) { Division.create(name: "1", date: Date.new(2000,1,1),
      number: 1, house: "commons", source_url: "", debate_url: "", motion: "",
      source_gid: "", debate_gid: "") }

      it { check_vote_combination("absent", false, "absent", false, 0, 0, 0) }
      it { check_vote_combination("absent", false, "aye",    false, 0, 0, 1) }
      it { check_vote_combination("absent", false, "no",     false, 0, 0, 1) }
      it { check_vote_combination("absent", false, "aye",    true,  0, 0, 1) }
      it { check_vote_combination("absent", false, "no",     true,  0, 0, 1) }
      it { check_vote_combination("aye",    false, "absent", false, 0, 0, 1) }
      it { check_vote_combination("aye",    false, "aye",    false, 1, 0, 0) }
      it { check_vote_combination("aye",    false, "no",     false, 0, 1, 0) }
      it { check_vote_combination("aye",    false, "aye",    true,  1, 0, 0) }
      it { check_vote_combination("aye",    false, "no",     true,  0, 1, 0) }
      it { check_vote_combination("no",     false, "absent", false, 0, 0, 1) }
      it { check_vote_combination("no",     false, "aye",    false, 0, 1, 0) }
      it { check_vote_combination("no",     false, "no",     false, 1, 0, 0) }
      it { check_vote_combination("no",     false, "aye",    true,  0, 1, 0) }
      it { check_vote_combination("no",     false, "no",     true,  1, 0, 0) }
      it { check_vote_combination("aye",    true,  "absent", false, 0, 0, 1) }
      it { check_vote_combination("aye",    true,  "aye",    false, 1, 0, 0) }
      it { check_vote_combination("aye",    true,  "no",     false, 0, 1, 0) }
      it { check_vote_combination("aye",    true,  "aye",    true,  1, 0, 0) }
      it { check_vote_combination("aye",    true,  "no",     true,  0, 1, 0) }
      it { check_vote_combination("no",     true,  "absent", false, 0, 0, 1) }
      it { check_vote_combination("no",     true,  "aye",    false, 0, 1, 0) }
      it { check_vote_combination("no",     true,  "no",     false, 1, 0, 0) }
      it { check_vote_combination("no",     true,  "aye",    true,  0, 1, 0) }
      it { check_vote_combination("no",     true,  "no",     true,  1, 0, 0) }
    end

    context "with votes on five divisions" do
      before :each do
        # Member A: 1 aye,    2 aye,     3 aye, 4 tellno, 5 absent
        # Member B: 1 absent, 2 tellaye, 3 no,  4 no,     5 no
        division1 = Division.create(name: "1", date: Date.new(2000,1,1),
        number: 1, house: "commons", source_url: "", debate_url: "", motion: "",
        source_gid: "", debate_gid: "")
        division2 = Division.create(name: "2", date: Date.new(2000,1,1),
        number: 2, house: "commons", source_url: "", debate_url: "", motion: "",
        source_gid: "", debate_gid: "")
        division3 = Division.create(name: "3", date: Date.new(2000,1,1),
        number: 3, house: "commons", source_url: "", debate_url: "", motion: "",
        source_gid: "", debate_gid: "")
        division4 = Division.create(name: "4", date: Date.new(2000,1,1),
        number: 4, house: "commons", source_url: "", debate_url: "", motion: "",
        source_gid: "", debate_gid: "")
        division5 = Division.create(name: "5", date: Date.new(2000,1,1),
        number: 5, house: "commons", source_url: "", debate_url: "", motion: "",
        source_gid: "", debate_gid: "")
        membera.votes.create(division: division1, vote: "aye")
        membera.votes.create(division: division2, vote: "aye")
        membera.votes.create(division: division3, vote: "aye")
        membera.votes.create(division: division4, vote: "no", teller: true)
        memberb.votes.create(division: division2, vote: "aye", teller: true)
        memberb.votes.create(division: division3, vote: "no")
        memberb.votes.create(division: division4, vote: "no")
        memberb.votes.create(division: division5, vote: "no")
      end

      it { expect(MemberDistance.calculate_nvotessame(membera.id, memberb.id)).to eq 2 }
      it { expect(MemberDistance.calculate_nvotesdiffer(membera.id, memberb.id)).to eq 1 }
      it { expect(MemberDistance.calculate_nvotesabsent(membera.id, membera.entered_house, membera.left_house, memberb.id, memberb.entered_house, memberb.left_house)).to eq 2 }

      it ".calculate_distances" do
        expect(Distance).to receive(:distance_a).with(2, 1, 2).and_return(0.1)
        expect(Distance).to receive(:distance_b).with(2, 1).and_return(0.2)
        expect(MemberDistance.calculate_distances(membera, memberb)).to eq({
          nvotessame: 2,
          nvotesdiffer: 1,
          nvotesabsent: 2,
          distance_a: 0.1,
          distance_b: 0.2
        })
      end
    end
  end
end
