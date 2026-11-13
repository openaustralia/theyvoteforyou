# frozen_string_literal: true

require "spec_helper"

describe DivisionInfo do
  describe "counts" do
    let(:persona) { create(:person) }
    let(:personb) { create(:person) }
    let(:membera) do
      Member.create!(id: 1, first_name: "Member", last_name: "A", gid: "", source_gid: "",
                     title: "", constituency: "", party: "A", house: "commons",
                     entered_house: Date.new(1999, 1, 1), left_house: Date.new(2001, 1, 1),
                     person: persona)
    end
    let(:memberb) do
      Member.create!(id: 2, first_name: "Member", last_name: "B", gid: "", source_gid: "",
                     title: "", constituency: "", party: "A", house: "commons",
                     entered_house: Date.new(1999, 1, 1), left_house: Date.new(2001, 1, 1),
                     person: personb)
    end

    let(:division1) do
      Division.create(id: 1, name: "1", date: Date.new(2000, 1, 1),
                      number: 1, house: "commons", source_url: "", debate_url: "", motion: "", debate_gid: "")
    end
    let(:division2) do
      Division.create(id: 2, name: "2", date: Date.new(2000, 1, 1),
                      number: 2, house: "commons", source_url: "", debate_url: "", motion: "", debate_gid: "")
    end
    # This division neither of the members could have voted on
    let(:division3) do
      Division.create(id: 3, name: "3", date: Date.new(2002, 1, 1),
                      number: 1, house: "commons", source_url: "", debate_url: "", motion: "", debate_gid: "")
    end

    before do
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
      expect(described_class.all_rebellion_counts).to eq({})
      expect(described_class.all_tells_counts).to eq({ 1 => 1 })
      expect(described_class.all_turnout_counts).to eq({ 1 => 2, 2 => 1 })
      expect(described_class.all_ayes_counts).to eq({ 2 => 1 })
      expect(described_class.all_noes_counts).to eq({ 1 => 2 })
      expect(described_class.all_aye_majority_counts).to eq({ 1 => -2, 2 => 1 })
      expect(described_class.all_possible_turnout_counts).to eq({ 1 => 2, 2 => 2 })
    end

    it do
      Vote.create(division: division1, member: membera, vote: "aye", teller: true)
      Vote.create(division: division1, member: memberb, vote: "aye")
      expect(described_class.all_rebellion_counts).to eq({ 1 => 2 })
      expect(described_class.all_tells_counts).to eq({ 1 => 1 })
      expect(described_class.all_turnout_counts).to eq({ 1 => 2 })
      expect(described_class.all_ayes_counts).to eq({ 1 => 2 })
      expect(described_class.all_noes_counts).to eq({})
      expect(described_class.all_aye_majority_counts).to eq({ 1 => 2 })
      expect(described_class.all_possible_turnout_counts).to eq({ 1 => 2, 2 => 2 })
    end
  end

  # The loader builds the cache one division at a time inside its transaction, so
  # these have to be scopable to a single division.
  # See https://github.com/openaustralia/theyvoteforyou/issues/1641
  describe ".update_divisions!" do
    let(:person) { create(:person) }
    let(:member) do
      Member.create!(first_name: "Member", last_name: "A", gid: "", source_gid: "",
                     title: "", constituency: "", party: "A", house: "commons",
                     entered_house: Date.new(1999, 1, 1), left_house: Date.new(2001, 1, 1),
                     person: person)
    end
    let(:division1) do
      Division.create!(name: "1", date: Date.new(2000, 1, 1), number: 1, house: "commons",
                       source_url: "", debate_url: "", motion: "", debate_gid: "")
    end
    let(:division2) do
      Division.create!(name: "2", date: Date.new(2000, 1, 1), number: 2, house: "commons",
                       source_url: "", debate_url: "", motion: "", debate_gid: "")
    end

    before do
      Vote.create!(division: division1, member: member, vote: "aye")
      Vote.create!(division: division2, member: member, vote: "no")
    end

    it "builds the cache row for the division it's given" do
      described_class.update_divisions!(division1.id)
      expect(division1.reload.division_info).to have_attributes(turnout: 1, aye_majority: 1)
    end

    it "leaves other divisions alone" do
      described_class.update_divisions!(division1.id)
      expect(division2.reload.division_info).to be_nil
    end

    it "accepts an array of ids" do
      described_class.update_divisions!([division1.id, division2.id])
      expect([division1.reload.division_info, division2.reload.division_info]).to all(be_present)
    end

    it "does nothing when given no divisions" do
      expect { described_class.update_divisions!([]) }.not_to change(described_class, :count)
    end

    it "updates an existing cache row rather than duplicating it" do
      described_class.update_divisions!(division1.id)
      expect { described_class.update_divisions!(division1.id) }.not_to change(described_class, :count)
    end

    it "produces the same result as a full rebuild" do
      described_class.update_divisions!([division1.id, division2.id])
      scoped = described_class.order(:division_id).pluck(:division_id, :turnout, :aye_majority, :possible_turnout)
      described_class.delete_all
      described_class.update_all!
      expect(described_class.order(:division_id).pluck(:division_id, :turnout, :aye_majority, :possible_turnout)).to eq(scoped)
    end
  end

  describe "#majority_fraction" do
    it "is 0 for a tied vote" do
      division = described_class.new(turnout: 100, aye_majority: 0)
      expect(division.majority_fraction).to eq(0.0)
    end

    it "is 1 for a unanimous aye vote" do
      division = described_class.new(turnout: 100, aye_majority: 100)
      expect(division.majority_fraction).to eq(1.0)
    end

    it "is 1 for a unanimous no vote" do
      division = described_class.new(turnout: 100, aye_majority: -100)
      expect(division.majority_fraction).to eq(1.0)
    end

    it "is 0.5 for a aye/no split of 75/25" do
      division = described_class.new(turnout: 100, aye_majority: 50)
      expect(division.majority_fraction).to eq(0.5)
    end
  end
end
