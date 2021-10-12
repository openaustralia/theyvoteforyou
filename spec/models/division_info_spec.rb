# frozen_string_literal: true

require "spec_helper"

describe DivisionInfo, type: :model do
  # TODO: Figure out why we need to do this horrible hack to remove the fixtures
  # we shouldn't have them loaded
  before :each do
    Member.delete_all
    Division.delete_all
    Whip.delete_all
    Vote.delete_all
  end

  describe "counts" do
    let(:membera) do
      Member.create(id: 1, first_name: "Member", last_name: "A", gid: "", source_gid: "",
                    title: "", constituency: "", party: "A", house: "commons",
                    entered_house: Date.new(1999, 1, 1), left_house: Date.new(2001, 1, 1))
    end
    let(:memberb) do
      Member.create(id: 2, first_name: "Member", last_name: "B", gid: "", source_gid: "",
                    title: "", constituency: "", party: "A", house: "commons",
                    entered_house: Date.new(1999, 1, 1), left_house: Date.new(2001, 1, 1))
    end

    let(:division1) do
      Division.create(id: 1, name: "1", date: Date.new(2000, 1, 1),
                      number: 1, house: "commons", source_url: "", debate_url: "", motion: "",
                      source_gid: "", debate_gid: "")
    end
    let(:division2) do
      Division.create(id: 2, name: "2", date: Date.new(2000, 1, 1),
                      number: 2, house: "commons", source_url: "", debate_url: "", motion: "",
                      source_gid: "", debate_gid: "")
    end
    # This division neither of the members could have voted on
    let(:division3) do
      Division.create(id: 3, name: "3", date: Date.new(2002, 1, 1),
                      number: 1, house: "commons", source_url: "", debate_url: "", motion: "",
                      source_gid: "", debate_gid: "")
    end

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
      expect(DivisionInfo.all_rebellion_counts).to eq({})
      expect(DivisionInfo.all_tells_counts).to eq({ 1 => 1 })
      expect(DivisionInfo.all_turnout_counts).to eq({ 1 => 2, 2 => 1 })
      expect(DivisionInfo.all_ayes_counts).to eq({ 2 => 1 })
      expect(DivisionInfo.all_noes_counts).to eq({ 1 => 2 })
      expect(DivisionInfo.all_aye_majority_counts).to eq({ 1 => -2, 2 => 1 })
      expect(DivisionInfo.all_possible_turnout_counts).to eq({ 1 => 2, 2 => 2 })
    end

    it do
      Vote.create(division: division1, member: membera, vote: "aye", teller: true)
      Vote.create(division: division1, member: memberb, vote: "aye")
      expect(DivisionInfo.all_rebellion_counts).to eq({ 1 => 2 })
      expect(DivisionInfo.all_tells_counts).to eq({ 1 => 1 })
      expect(DivisionInfo.all_turnout_counts).to eq({ 1 => 2 })
      expect(DivisionInfo.all_ayes_counts).to eq({ 1 => 2 })
      expect(DivisionInfo.all_noes_counts).to eq({})
      expect(DivisionInfo.all_aye_majority_counts).to eq({ 1 => 2 })
      expect(DivisionInfo.all_possible_turnout_counts).to eq({ 1 => 2, 2 => 2 })
    end
  end

  describe "#majority_fraction" do
    it "should be 0 for a tied vote" do
      division = DivisionInfo.new(turnout: 100, aye_majority: 0)
      expect(division.majority_fraction).to eq(0.0)
    end

    it "should be 1 for a unanimous aye vote" do
      division = DivisionInfo.new(turnout: 100, aye_majority: 100)
      expect(division.majority_fraction).to eq(1.0)
    end

    it "should be 1 for a unanimous no vote" do
      division = DivisionInfo.new(turnout: 100, aye_majority: -100)
      expect(division.majority_fraction).to eq(1.0)
    end

    it "should be 0.5 for a aye/no split of 75/25" do
      division = DivisionInfo.new(turnout: 100, aye_majority: 50)
      expect(division.majority_fraction).to eq(0.5)
    end
  end
end
