# frozen_string_literal: true

require "spec_helper"

describe DivisionSummaryPipeline::SnapshotRecord do
  # The closure from context_builder_spec.rb: a member moves "That the question be now put." (that
  # the debate end and the vote be taken now) and the House divides on it, so Stage 2 settles on
  # Template 22, the closure template.
  let(:parlparse_xml) do
    <<~XML
      <debates>
        <major-heading id="d1" url="http://example.org/1">BILLS</major-heading>
        <minor-heading id="d2" url="http://example.org/1">Border Processing Amendment Bill 2026</minor-heading>
        <speech id="d3" speakerid="uk.org.publicwhip/member/1" speakername="Daniel Whitfield" time="10:10:00" url="http://example.org/1">
          <p>I move: That the question be now put.</p>
        </speech>
        <speech id="d4" nospeaker="true" time="10:11:00" url="http://example.org/1">
          <p pwmotiontext="moved">That the question be now put.</p>
        </speech>
        <division divdate="2026-08-19" divnumber="1" id="d5" nospeaker="true" time="10:15:00" url="http://example.org/1">
          <divisioncount ayes="82" noes="54" pairs="0" tellerayes="0" tellernoes="0"/>
          <memberlist vote="aye">
            <member id="uk.org.publicwhip/member/1" vote="aye">Daniel Whitfield</member>
          </memberlist>
          <memberlist vote="no">
            <member id="uk.org.publicwhip/member/2" vote="no">Alex Pemberton</member>
          </memberlist>
        </division>
      </debates>
    XML
  end
  let(:division_data) do
    { id: 1052, house: "representatives", name: "Closure of Debate", date: "2026-08-19", number: 1,
      clock_time: "10:15 AM", aye_votes: 82, no_votes: 54, result: "passed" }
  end
  let(:packet) { DivisionSummaryPipeline::ContextBuilder.build(division_data, xml_content: parlparse_xml) }

  describe ".build" do
    subject(:block) { described_class.build(packet) }

    it "records Stage 2's decision and the rule that made it" do
      expect(block["route"]).to include("mode" => "deterministic", "template" => 22, "allowed" => [22],
                                        "forbidden" => [])
      expect(block["route"]["rule"]).to eq(packet.routing.rule_name.to_s)
    end

    it "records who moved the motion, how Stage 1 found them, and the terms they moved" do
      expect(block["mover"]).to include("name" => "Daniel Whitfield", "found_by" => "recent_move", "speech" => "d3")
      expect(block["motion"]).to include("found" => true, "found_in" => "mover_speech", "terms_moved" => true,
                                         "text" => "That the question be now put.")
    end

    it "records the facts Hansard gives about the vote, without the database's id" do
      expect(block["facts"]).to include("house" => "representatives", "date" => "2026-08-19", "number" => 1,
                                        "time" => "10:15", "ayes" => 82, "noes" => 54, "result" => "passed")
      expect(block.to_s).not_to include("1052")
    end

    it "keeps its fields in a fixed order, so every entry reads the same way" do
      expect(block.keys).to eq(%w[facts hansard_division source heading context_level route question motion mover
                                  circulation proposer closed_template followup speeches earlier_debate limitation
                                  warnings])
    end

    it "puts what RouteSnapshot adds from outside Stages 1 and 2 straight after the facts" do
      sources = { "parliament" => 48, "hansard" => "proof", "hansard_read" => ["representatives/2026-08-19"] }
      expect(described_class.build(packet, sources).keys.first(4)).to eq(%w[facts parliament hansard hansard_read])
    end

    it "lists the bills alphabetically, since the database returns them in no fixed order" do
      packet = DivisionSummaryPipeline::ContextBuilder.build(
        division_data.merge(bill_titles: ["Zeta Bill 2026", "Alpha Bill 2026"]), xml_content: parlparse_xml
      )
      expect(described_class.build(packet)["facts"]["bills"]).to eq(["Alpha Bill 2026", "Zeta Bill 2026"])
    end

    it "gives the same entry every time it is built" do
      again = described_class.build(DivisionSummaryPipeline::ContextBuilder.build(division_data,
                                                                                  xml_content: parlparse_xml))
      expect(again).to eq(block)
    end
  end

  describe ".key" do
    it "names a division by house, date and number" do
      division = build(:division, house: "senate", date: Date.new(2026, 9, 17), number: 6)
      expect(described_class.key(division)).to eq("senate_2026-09-17_6")
    end
  end

  describe ".shorten_text" do
    let(:long_text) { (1..50).map { |n| "word#{n}" }.join(" ") }

    it "leaves text of 40 words or fewer in full" do
      text = (1..40).map { |n| "word#{n}" }.join(" ")
      expect(described_class.shorten_text(text)).to eq(text)
    end

    it "shows longer text as its first and last 20 words, its word count and a hash of the whole" do
      first = (1..20).map { |n| "word#{n}" }.join(" ")
      last = (31..50).map { |n| "word#{n}" }.join(" ")
      hash = Digest::SHA256.hexdigest(long_text)[0, 12]
      expect(described_class.shorten_text(long_text)).to eq("#{first} ... (50 words) ... #{last} [hash: #{hash}]")
    end

    it "changes the line when a word in the hidden middle changes" do
      changed = long_text.sub("word25", "changed")
      expect(described_class.shorten_text(changed)).not_to eq(described_class.shorten_text(long_text))
    end
  end
end
