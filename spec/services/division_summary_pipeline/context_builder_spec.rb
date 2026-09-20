# frozen_string_literal: true

require "spec_helper"
require "nokogiri"

describe DivisionSummaryPipeline::ContextBuilder do
  # A minimal but real ParlParse <debates> document - the shape DataLoader::DebatesXml/
  # DivisionXml actually parse (see spec/fixtures/2009-11-25.xml), not the <hansard>
  # shape an earlier draft of this spec used, which no other part of the app reads.
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

  describe ".build" do
    context "with a matching <division> in the supplied XML" do
      let(:division_data) do
        { id: 1052, house: "representatives", name: "Closure of Debate", date: "2026-08-19", number: 1, clock_time: "10:15 AM" }
      end

      it "reads the operative question and heading from the matched DataLoader::DivisionXml, not a second parser" do
        packet = described_class.build(division_data, xml_content: parlparse_xml)

        expect(packet.speaker_question).to eq("That the question be now put.")
        # DataLoader::DivisionXml#name title-cases the raw ALL-CAPS Hansard heading -
        # this asserts ContextBuilder reads that existing method rather than the raw text.
        expect(packet.hansard_context).to include("Bills")
        expect(packet.hansard_context).to include("Border Processing Amendment Bill 2026")
        expect(packet.procedural_decision.template_id).to eq(22)
      end

      it "works the same way for a real Division record as for a plain Hash" do
        division = create(:division, date: Date.new(2026, 8, 19), number: 1, house: "representatives")
        packet = described_class.build(division, xml_content: parlparse_xml)

        expect(packet.speaker_question).to eq("That the question be now put.")
        expect(packet.procedural_decision.template_id).to eq(22)
      end
    end

    context "when no <division> in the XML matches this division's number" do
      let(:division_data) { { id: 1, house: "representatives", name: "Unrelated", date: "2026-08-19", number: 99 } }

      it "falls back to the division's own motion text rather than raising" do
        packet = described_class.build(division_data, xml_content: parlparse_xml)

        expect(packet).to be_present
        expect(packet.division_id).to eq(1)
      end
    end

    context "when no XML content is supplied and none can be fetched" do
      let(:division_data) { { id: 1052, house: "representatives", name: "Some Division", date: "2026-08-19", number: 1 } }

      it "falls back gracefully instead of raising" do
        packet = described_class.build(division_data)

        expect(packet).to be_present
        expect(packet.date).to eq("2026-08-19")
        expect(packet.speaker_question).to eq(described_class::DEFAULT_SPEAKER_QUESTION)
      end
    end

    it "fetches via DataLoader::Debates.fetch_xml_document rather than its own HTTP client, so there is one fetch mechanism to maintain" do
      division_data = { id: 1052, house: "representatives", name: "Closure of Debate", date: "2026-08-19", number: 1 }
      doc = Nokogiri::XML(parlparse_xml)
      allow(DataLoader::Debates).to receive(:fetch_xml_document).with("representatives", "2026-08-19").and_return(doc)

      packet = described_class.build(division_data)

      expect(packet.speaker_question).to eq("That the question be now put.")
      expect(DataLoader::Debates).to have_received(:fetch_xml_document).with("representatives", "2026-08-19")
    end
  end
end
