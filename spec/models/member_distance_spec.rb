# frozen_string_literal: true

require "spec_helper"

describe MemberDistance, type: :model do
  # Just making sure we're not loading any fixtures
  it { expect(Member.all).to be_empty }

  describe "calculating cache values" do
    let(:persona) { create(:person) }
    let(:personb) { create(:person) }
    let(:membera) do
      Member.create!(id: 1, first_name: "Member", last_name: "A", gid: "A", source_gid: "A",
                     title: "", constituency: "foo", party: "Party", house: "commons",
                     entered_house: Date.new(1990, 1, 1), left_house: Date.new(2001, 1, 1),
                     person: persona)
    end
    let(:memberb) do
      Member.create!(id: 2, first_name: "Member", last_name: "B", gid: "B", source_gid: "B",
                     title: "", constituency: "bar", party: "Party", house: "commons",
                     entered_house: Date.new(1999, 1, 1), left_house: Date.new(2010, 1, 1),
                     person: personb)
    end

    it do
      expect(described_class.calculate_distances(membera, memberb)).to eq(
        { nvotessame: 0, nvotesdiffer: 0, distance_b: -1 }
      )
    end

    def check_vote_combination(vote1, vote2, same, differ)
      membera.votes.create(division: division, vote: vote1) unless vote1 == "absent"
      memberb.votes.create(division: division, vote: vote2) unless vote2 == "absent"
      r = MemberDistance.calculate_distances(membera, memberb)
      expect(r[:nvotessame]).to eq same
      expect(r[:nvotesdiffer]).to eq differ
    end

    context "with votes in one division that only member A could vote on" do
      let(:division) do
        Division.create(name: "1", date: Date.new(1995, 1, 1),
                        number: 1, house: "commons", source_url: "", debate_url: "", motion: "", debate_gid: "")
      end

      it { check_vote_combination("absent", "absent", 0, 0) }
      it { check_vote_combination("aye",    "absent", 0, 0) }
      it { check_vote_combination("no",     "absent", 0, 0) }
    end

    context "with votes in one division that both members could vote on" do
      let(:division) do
        Division.create(name: "1", date: Date.new(2000, 1, 1),
                        number: 1, house: "commons", source_url: "", debate_url: "", motion: "", debate_gid: "")
      end

      it { check_vote_combination("absent", "absent", 0, 0) }
      it { check_vote_combination("absent", "aye",    0, 0) }
      it { check_vote_combination("absent", "no",     0, 0) }
      it { check_vote_combination("aye",    "absent", 0, 0) }
      it { check_vote_combination("aye",    "aye",    1, 0) }
      it { check_vote_combination("aye",    "no",     0, 1) }
      it { check_vote_combination("no",     "absent", 0, 0) }
      it { check_vote_combination("no",     "aye",    0, 1) }
      it { check_vote_combination("no",     "no",     1, 0) }
    end

    context "with votes on five divisions" do
      before do
        # Member A: 1 aye,    2 aye,     3 aye, 4 tellno, 5 absent
        # Member B: 1 absent, 2 tellaye, 3 no,  4 no,     5 no
        division1 = Division.create(name: "1", date: Date.new(2000, 1, 1),
                                    number: 1, house: "commons", source_url: "", debate_url: "", motion: "", debate_gid: "")
        division2 = Division.create(name: "2", date: Date.new(2000, 1, 1),
                                    number: 2, house: "commons", source_url: "", debate_url: "", motion: "", debate_gid: "")
        division3 = Division.create(name: "3", date: Date.new(2000, 1, 1),
                                    number: 3, house: "commons", source_url: "", debate_url: "", motion: "", debate_gid: "")
        division4 = Division.create(name: "4", date: Date.new(2000, 1, 1),
                                    number: 4, house: "commons", source_url: "", debate_url: "", motion: "", debate_gid: "")
        division5 = Division.create(name: "5", date: Date.new(2000, 1, 1),
                                    number: 5, house: "commons", source_url: "", debate_url: "", motion: "", debate_gid: "")
        membera.votes.create(division: division1, vote: "aye")
        membera.votes.create(division: division2, vote: "aye")
        membera.votes.create(division: division3, vote: "aye")
        membera.votes.create(division: division4, vote: "no")
        memberb.votes.create(division: division2, vote: "aye")
        memberb.votes.create(division: division3, vote: "no")
        memberb.votes.create(division: division4, vote: "no")
        memberb.votes.create(division: division5, vote: "no")
      end

      it ".calculate_distances" do
        distance_b = instance_double(Distance, distance: 0.2)
        allow(Distance).to receive(:new).with(same: 2, differ: 1).and_return(distance_b)
        expect(described_class.calculate_distances(membera, memberb)).to eq({
                                                                              nvotessame: 2,
                                                                              nvotesdiffer: 1,
                                                                              distance_b: 0.2
                                                                            })
      end
    end
  end
end
