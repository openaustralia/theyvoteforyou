# frozen_string_literal: true

require "spec_helper"
require "nokogiri"

# Fictional members and motions in the shape current ParlParse XML has.
describe DivisionSummaryPipeline::Transcript do
  def speech(inner_xml, id:, name: "Morgan Treloar", gid: "uk.org.publicwhip/lord/900001", time: "13:27")
    node = Nokogiri::XML("<speech id=\"#{id}\" speakername=\"#{name}\" speakerid=\"#{gid}\" time=\"#{time}\">" \
                         "#{inner_xml}</speech>").root
    DataLoader::SpeechText.context_speech(node)
  end

  let(:mover_speech) do
    speech(<<~XML, id: "s1")
      <p>Rural students pay more to study. Mr Example said so in No. 3 of his reports.</p>
      <p>I move the second reading amendment on sheet 9001:</p>
      <p class="italic">At the end of the motion, add ", but the Senate calls on the Government to fund the Example (Regional Access) Scheme".</p>
      <p>The Senate should support it.</p>
    XML
  end
  let(:chair_speech) do
    speech("<p>The question is that the amendment moved by Senator Treloar be agreed to.</p>",
           id: "s2", name: "Robin Castellan", gid: "uk.org.publicwhip/lord/900002", time: "13:30")
  end
  let(:transcript) do
    described_class.build(heading: "Bills &#8212; Example Bill 2026; Second Reading",
                          speeches: [mover_speech, chair_speech], question_speech_id: "s2")
  end

  describe "units" do
    it "cuts a member's own words into sentences, without breaking at titles or \"No. 3\"" do
      prose = transcript.speech(1).units.select { |unit| unit.kind == :prose }.map(&:text)

      expect(prose).to eq(["Rural students pay more to study.", "Mr Example said so in No. 3 of his reports.",
                           "The Senate should support it."])
    end

    it "keeps the move, the motion and the chair's question whole, and says which is which" do
      kinds = transcript.units.to_h { |unit| [unit.id, unit.kind] }

      expect(kinds).to eq("S1.1" => :prose, "S1.2" => :prose, "S1.3" => :move, "S1.4" => :motion,
                          "S1.5" => :prose, "S2.1" => :chair)
    end

    # Members often give their reasons in the same paragraph as the move.
    it "treats the reasons before \"I move\" in the same paragraph as the member's own words" do
      node = speech("<p>Students deserve better. For these reasons, I move the amendment:</p>" \
                    "<p class=\"italic\">That the Senate notes it.</p>", id: "s9")
      units = described_class.build(heading: "Bills", speeches: [node]).speech(1).units

      expect(units.map { |unit| [unit.kind, unit.text] })
        .to eq([[:prose, "Students deserve better."], [:move, "For these reasons, I move the amendment:"],
                [:motion, "That the Senate notes it."]])
    end

    it "finds a unit whatever case or spacing the model used for its ID" do
      expect(transcript.unit(" s1.4 ").kind).to eq(:motion)
      expect(transcript.unit("S9.9")).to be_nil
    end

    it "gives the last move's introduction and terms" do
      speech = transcript.speech(1)

      expect(transcript.last_move_units(speech, :move).map(&:id)).to eq(["S1.3"])
      expect(transcript.last_move_units(speech, :motion).map(&:id)).to eq(["S1.4"])
    end
  end

  describe "#passages" do
    it "quotes consecutive units as the exact run of text they came from" do
      passages = transcript.passages(%w[S1.2 S1.1])

      expect(passages.size).to eq(1)
      expect(passages.first.text).to eq("Rural students pay more to study. Mr Example said so in No. 3 of his reports.")
    end

    it "keeps separate excerpts separate, so a gap is never joined over" do
      expect(transcript.passages(%w[S1.1 S1.5]).map(&:text))
        .to eq(["Rural students pay more to study.", "The Senate should support it."])
    end

    it "keeps a paragraph break inside a run" do
      expect(transcript.passages(%w[S1.3 S1.4]).first.text).to start_with("I move the second reading amendment on sheet 9001:\n\nAt the end")
    end
  end

  describe "#anchor" do
    it "returns Hansard's own text for a phrase, whatever the model did to its case and punctuation" do
      anchor = transcript.anchor("S1.4", "example regional access scheme")

      expect(anchor.problem).to be_nil
      expect(anchor.text).to eq("Example (Regional Access) Scheme")
    end

    it "keeps a closing bracket the phrase ends inside" do
      expect(transcript.anchor("S1.4", "the Example (Regional Access").text).to eq("the Example (Regional Access)")
    end

    it "refuses a phrase that is not in that unit, even if it is elsewhere in the debate" do
      expect(transcript.anchor("S1.1", "Example (Regional Access) Scheme").problem).to eq(:not_found)
      expect(transcript.anchor("S7.1", "anything").problem).to eq(:no_such_unit)
    end
  end

  describe "#prompt_text" do
    it "shows every unit with its ID, and marks the chair's question" do
      text = transcript.prompt_text

      expect(text).to include("--- S1: Morgan Treloar, 13:27 ---")
      expect(text).to include("[S1.1] Rural students pay more to study.")
      expect(text).to include("[S1.4 motion] At the end of the motion")
      expect(text).to include("--- S2: Robin Castellan, 13:30 (the chair putting this division's question) ---")
      expect(text).to include("[S2.1 chair] The question is")
    end
  end

  describe ".from_record" do
    it "treats the Division record's stored text as one unnamed speech" do
      record = described_class.from_record(heading: "Motions", text: "That the Senate notes the report.\nIt is late.")

      expect(record.speech(1).label).to eq("Unnamed speaker")
      expect(record.units.map(&:text)).to eq(["That the Senate notes the report.", "It is late."])
    end
  end
end
