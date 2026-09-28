# frozen_string_literal: true

require "spec_helper"

describe DivisionSummaryPipeline::MoverFinder do
  def speech(speaker, text, moved_text: nil, gid: nil)
    { speaker: speaker, speaker_gid: gid, time: "11:42", text: text, moved_text: moved_text }
  end

  let(:amendment_by_treloar) do
    speech("Morgan Treloar", "I move the second reading amendment on sheet 9001: ...", moved_text: "At the end of the motion, add ...")
  end

  let(:amendment_by_dunstan) do
    speech("Priya Dunstan", "I move the opposition's amendment: ...", moved_text: "At the end of the motion, add different words")
  end

  let(:chair) { speech("Casey Whitlow", "The question is that the amendment be agreed to.") }

  it "takes the mover the chair names, by surname, over a later move by someone else" do
    result = described_class.find(
      question: "The question is that the second reading amendment moved by Senator Treloar on sheet 9001 be agreed to.",
      speeches: [amendment_by_treloar, amendment_by_dunstan, chair]
    )

    expect(result.member.name).to eq("Morgan Treloar")
    expect(result.moved_text).to eq("At the end of the motion, add ...")
  end

  it "takes the move just before the question when the chair names nobody" do
    adjourn = speech("Sam Okafor", "I move: That the debate be adjourned.", moved_text: "That the debate be adjourned.")

    result = described_class.find(question: "The question is that the debate be adjourned.", speeches: [adjourn, chair])

    expect(result.member.name).to eq("Sam Okafor")
  end

  # Further back it may be a different motion, such as an amendment moved long before a second
  # reading question is put.
  it "does not take an unnamed move from well before the question" do
    speeches = [amendment_by_treloar] + Array.new(5) { speech("Riley Ng", "A long speech about the bill.") } + [chair]

    expect(described_class.find(question: "The question is that the bill be now read a second time.", speeches: speeches)).to be_nil
  end

  # Another senator often moves a notice on its owner's behalf.
  it "treats \"standing in the name of\" as a weaker hint than a recent move by someone else" do
    result = described_class.find(
      question: "The question is that business of the Senate No. 3 standing in the name of Senator Ashworth as amended be agreed to.",
      speeches: [amendment_by_dunstan, chair]
    )

    expect(result.member.name).to eq("Priya Dunstan")
  end

  it "does not attribute a named mover's motion to someone else when their move is not in the excerpt" do
    result = described_class.find(
      question: "The question is that the amendment moved by Senator Treloar be agreed to.",
      speeches: [amendment_by_dunstan, chair]
    )

    expect(result).to be_nil
  end

  context "with member records" do
    let!(:member) do
      create(:member, person: create(:person), gid: "uk.org.publicwhip/member/9101", first_name: "Robin", last_name: "Carrow",
                      constituency: "Wattleford", party: "Liberal Party", house: "representatives",
                      entered_house: "2022-05-21", left_house: "9999-12-31")
    end

    it "resolves the moving speech's speaker id to the member, with party and profile link" do
      suspension = speech("Robin Carrow", "I move: ...", moved_text: "That so much of the standing orders be suspended as would prevent ...",
                                                         gid: "uk.org.publicwhip/member/9101")

      result = described_class.find(question: "The question is the motion moved by the member for Wattleford be agreed to.",
                                    speeches: [suspension, chair])

      expect(result.member.member).to eq(member)
      expect(result.member.party).to eq("Liberal Party")
      expect(result.member.link).to eq("/people/representatives/wattleford/robin_carrow")
    end

    # A deferred division: the chair names the mover, whose speech was on an earlier day.
    it "looks up a named electorate directly when the move is not in the excerpt" do
      result = described_class.find(question: "The question is whether the amendment moved by the honourable member for Wattleford be agreed to.",
                                    speeches: [chair], house: "representatives", date: "2026-05-14")

      expect(result.member.member).to eq(member)
      expect(result.speech).to be_nil
    end
  end
end
