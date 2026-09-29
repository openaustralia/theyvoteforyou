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
        expect(packet.transcript.prompt_text).to include("Bills")
        expect(packet.transcript.prompt_text).to include("Border Processing Amendment Bill 2026")
        expect(packet.routing.template_id).to eq(22)
      end

      it "works the same way for a real Division record as for a plain Hash" do
        division = create(:division, date: Date.new(2026, 8, 19), number: 1, house: "representatives")
        packet = described_class.build(division, xml_content: parlparse_xml)

        expect(packet.speaker_question).to eq("That the question be now put.")
        expect(packet.routing.template_id).to eq(22)
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

    # Stage 1 takes the speeches immediately before the <division> element, which assumes the
    # debate next to a division is the debate about it. Successive and deferred divisions break
    # that assumption in a knowable way (KNOWN_ISSUES.md, KI-6), so the packet says so.
    describe "context warnings" do
      let(:successive_divisions_xml) do
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
            </division>
            <division divdate="2026-08-19" divnumber="2" id="d6" nospeaker="true" time="10:17:00" url="http://example.org/1">
              <divisioncount ayes="80" noes="56" pairs="0" tellerayes="0" tellernoes="0"/>
            </division>
          </debates>
        XML
      end

      it "says nothing when the debate sits immediately before the division" do
        division_data = { id: 1052, house: "representatives", name: "Closure of Debate", date: "2026-08-19",
                          number: 1, clock_time: "10:15 AM" }

        packet = described_class.build(division_data, xml_content: parlparse_xml)

        expect(packet.context_warnings).to be_empty
      end

      it "warns when this division follows another with no debate between them" do
        division_data = { id: 1053, house: "representatives", name: "Closure of Debate", date: "2026-08-19",
                          number: 2, clock_time: "10:17 AM" }

        packet = described_class.build(division_data, xml_content: successive_divisions_xml)

        expect(packet.context_warnings.join).to include("immediately follows another with no debate between them")
        expect(packet.context_warnings.join).to include("No debate speeches were found")
      end

      # House S.O. 133: on Mondays divisions called between 10 am and 12 noon are put after
      # 12 noon, without further debate. 24 August 2026 is a Monday.
      it "warns about the part of a Monday when deferred divisions are put" do
        division_data = { id: 1054, house: "representatives", name: "Closure of Debate", date: "2026-08-24",
                          number: 1, clock_time: "12:05 PM" }

        packet = described_class.build(division_data, xml_content: parlparse_xml)

        expect(packet.context_warnings.join).to include("Standing Order 133")
      end

      it "does not raise that warning for the Senate, which has no such rule" do
        division_data = { id: 1055, house: "senate", name: "Closure of Debate", date: "2026-08-24",
                          number: 1, clock_time: "12:05 PM" }

        packet = described_class.build(division_data, xml_content: parlparse_xml)

        expect(packet.context_warnings.join).not_to include("Standing Order 133")
      end

      it "says so when it had to fall back to the Division record's own motion text" do
        division_data = { id: 1, house: "representatives", name: "Some Division", date: "2026-08-19", number: 99 }

        packet = described_class.build(division_data, xml_content: parlparse_xml)

        expect(packet.context_warnings.join).to include("No Hansard XML was available")
      end
    end

    # Current ParlParse XML differs from the fixture above in ways that broke every division
    # in the September 2026 test runs: no pwmotiontext (a motion is <p class="italic"> after
    # "I move:"), paragraphs with nothing between them, and the chair recorded as a named
    # member putting the question, often only by reference.
    describe "Hansard in the shape current ParlParse produces" do
      def debates(date, body)
        "<debates><major-heading id=\"h1\" url=\"x\">BILLS</major-heading>#{body}</debates>".gsub("DATE", date)
      end

      def division_element(number, time)
        "<division divdate=\"DATE\" divnumber=\"#{number}\" id=\"d#{number}\" time=\"#{time}\" url=\"x\">" \
          "<divisioncount ayes=\"40\" noes=\"30\" pairs=\"0\" tellerayes=\"0\" tellernoes=\"0\"/></division>"
      end

      let(:suspension_xml) do
        debates("2026-08-20", <<~XML)
          <minor-heading id="h2" url="x">Example Report; Suspension of Standing Orders</minor-heading>
          <speech id="s1" speakerid="uk.org.publicwhip/lord/900101" speakername="Morgan Treloar" time="15:30:00" url="x"><p>Pursuant to contingent notice standing in my name, I move:</p><p class="italic">That so much of the standing orders be suspended as would prevent the Senate:</p><p class="italic">(a) considering the report forthwith; and</p><p class="italic">(b) voting on it today.</p></speech>
          <speech id="s2" speakerid="uk.org.publicwhip/lord/900102" speakername="Casey Whitlow" time="15:44:00" url="x"><p>The question is that the motion moved by Senator Treloar be agreed to.</p></speech>
          #{division_element(2, '15:45:00')}
        XML
      end

      let(:suspension) do
        described_class.build({ id: 1, house: "senate", date: "2026-08-20", number: 2, clock_time: "3:45 PM" },
                              xml_content: suspension_xml)
      end

      it "keeps a motion's paragraphs apart, as members and models quote them" do
        expect(suspension.transcript.units.map(&:text))
          .to include("That so much of the standing orders be suspended as would prevent the Senate:",
                      "(a) considering the report forthwith; and")
        expect(suspension.transcript.passages(%w[S1.2 S1.3]).first.text)
          .to eq("That so much of the standing orders be suspended as would prevent the Senate:\n\n(a) considering the report forthwith; and")
      end

      it "routes a question put by reference on the motion as moved, and knows who moved it" do
        expect(suspension.routing.template_id).to eq(17)
        expect(suspension.mover.speech[:speaker]).to eq("Morgan Treloar")
        expect(suspension.mover.moved_text).to start_with("That so much of the standing orders be suspended")
      end

      # The widened retry is routed on the first packet, not on the start of the sitting day,
      # which is some other debate (KNOWN_ISSUES.md, KI-27).
      it "keeps a routing decision it is given rather than routing again" do
        given = DivisionSummaryPipeline::RoutingDecision.settled(17, rule_name: "GIVEN", reason: "from the first packet")
        packet = described_class.build({ id: 1, house: "senate", date: "2026-08-20", number: 2, clock_time: "3:45 PM" },
                                       xml_content: suspension_xml, context_level: :sitting_day, routing: given)

        expect(packet.routing).to be(given)
        expect(packet.context_level).to eq(:sitting_day)
      end

      it "marks the chair putting the question, and finds the motion and its introduction by rule" do
        expect(suspension.question_speech.label).to eq("Casey Whitlow")
        expect(suspension.transcript.unit("S2.1").kind).to eq(:chair)
        expect(suspension).to be_motion_found
        expect(suspension).to be_question_by_reference
        expect(suspension.transcript.last_move_units(suspension.mover_speech, :move).map(&:text))
          .to eq(["Pursuant to contingent notice standing in my name, I move:"])
      end

      # A Monday division at 12.05 is in the window when deferred divisions are put, but a
      # motion moved at 12.00 was put there and then.
      it "does not warn about the Monday deferral window when the motion was moved inside it" do
        xml = debates("2026-08-24", <<~XML)
          <minor-heading id="h2" url="x">Example Bill 2026; Consideration of Senate Message</minor-heading>
          <speech id="s1" speakerid="uk.org.publicwhip/member/900201" speakername="Robin Carrow" time="12:00:00" url="x"><p>I move:</p><p class="italic">That the amendments be considered at the next sitting.</p></speech>
          <speech id="s2" speakerid="uk.org.publicwhip/member/900202" speakername="Casey Whitlow" time="12:01:00" url="x"><p>The question is that the amendments be considered at the next sitting.</p></speech>
          #{division_element(1, '12:05:00')}
        XML

        packet = described_class.build({ id: 1, house: "representatives", date: "2026-08-24", number: 1, clock_time: "12:05 PM" },
                                       xml_content: xml)

        expect(packet.context_warnings.join).not_to include("Standing Order 133")
        expect(packet.routing.template_id).to eq(19)
      end

      # Only the first question of a deferred run says it was deferred.
      it "carries the chair's deferral along a run of divisions" do
        xml = debates("2026-08-20", <<~XML)
          <minor-heading id="h2" url="x">Example Bill 2026; Second Reading</minor-heading>
          <speech id="s1" speakerid="uk.org.publicwhip/member/900202" speakername="Casey Whitlow" time="09:20:00" url="x"><p>In accordance with standing order 133, I shall now proceed to put the question on the amendment moved by the member for Exampleton, on which a division was called for and deferred.</p><p>The question is that the amendment be agreed to.</p></speech>
          #{division_element(1, '09:21:00')}
          <speech id="s2" speakerid="uk.org.publicwhip/member/900202" speakername="Casey Whitlow" time="09:27:00" url="x"><p>The question now is that the amendment moved by the member for Fairview be agreed to.</p></speech>
          #{division_element(2, '09:28:00')}
        XML

        packet = described_class.build({ id: 2, house: "representatives", date: "2026-08-20", number: 2, clock_time: "9:28 AM" },
                                       xml_content: xml)

        expect(packet.context_warnings.join).to include("immediately follows another with no debate between them")
        expect(packet.context_warnings.join).to include("The chair's words show this division was deferred")
        expect(packet.routing.allowed_templates).to eq([2])
      end

      # A deferred division is put without debate, often on another sitting day, so the
      # amendment it decides was moved in an earlier day's XML under the same heading.
      it "brings in the amendment from the earlier sitting day it was moved on" do
        heading = "<minor-heading id=\"h2\" url=\"x\">Example Bill 2026; Second Reading</minor-heading>"
        earlier_day = debates("2026-08-18", <<~XML)
          #{heading}
          <speech id="s1" speakerid="uk.org.publicwhip/member/900301" speakername="Robin Carrow" time="12:33:00" url="x"><p>I rise to speak, and I move:</p><p class="italic">That all words after "That" be omitted with a view to substituting the following words: "whilst not declining to give the bill a second reading, the House notes the cost to small business".</p><p>Small businesses cannot absorb these costs.</p></speech>
        XML
        today = debates("2026-08-20", <<~XML)
          #{heading}
          <speech id="s2" speakerid="uk.org.publicwhip/member/900202" speakername="Casey Whitlow" time="09:20:00" url="x"><p>In accordance with standing order 133, I shall now proceed to put the question on the amendment moved by the member for Exampleton.</p><p>The question is that the amendment be agreed to.</p></speech>
          #{division_element(1, '09:21:00')}
        XML
        fetcher = ->(_house, date) { Nokogiri::XML(earlier_day) if date == "2026-08-18" }
        # The chair names the mover only by electorate, which takes the member's record to match.
        create(:member, person: create(:person), gid: "uk.org.publicwhip/member/900301", first_name: "Robin",
                        last_name: "Carrow", constituency: "Exampleton", party: "Example Party", house: "representatives",
                        entered_house: "2020-01-01", left_house: "9999-12-31")

        packet = described_class.build({ id: 1, house: "representatives", date: "2026-08-20", number: 1, clock_time: "9:21 AM" },
                                       xml_content: today, xml_fetcher: fetcher)

        expect(packet.earlier_debate_dates).to eq(["2026-08-18"])
        expect(packet.transcript.prompt_text).to include("whilst not declining to give the bill a second reading")
        expect(packet.mover.member.name).to eq("Robin Carrow")
      end

      # As on 20 August 2026: the amendment is moved in the second reading debate, and once the
      # guillotine's time expires the chair puts it, and then the second reading, under the
      # bill's "; Limitation of Debate" heading.
      context "when a guillotine's time has expired" do
        let(:bills) { "<bills><bill id=\"r9001\" url=\"x\">Example Bill 2026</bill></bills>" }
        let(:chair) { "speakerid=\"uk.org.publicwhip/lord/900102\" speakername=\"Casey Whitlow\"" }
        let(:guillotine_xml) do
          debates("2026-08-20", <<~XML)
            <minor-heading id="h2" url="x">Example Bill 2026; Second Reading</minor-heading>
            #{bills}
            <speech id="s1" speakerid="uk.org.publicwhip/lord/900101" speakername="Morgan Treloar" time="12:19:00" url="x"><p>These powers go too far. I move:</p><p class="italic">Omit all words after "That", substitute "the Senate rejects the bill".</p></speech>
            <minor-heading id="h3" url="x">Example Bill 2026; Limitation of Debate</minor-heading>
            #{bills}
            <speech id="s2" #{chair} time="13:15:00" url="x"><p>Pursuant to order agreed on 18 August 2026, the time allotted for consideration of 2 bills has expired. I'll now put the question on the remaining stages of the bills. The question is that the second reading amendment moved by Senator Treloar be agreed to.</p></speech>
            <division divdate="DATE" divnumber="1" id="d1" time="13:19:00" url="x">#{bills}<divisioncount ayes="12" noes="27" pairs="0" tellerayes="0" tellernoes="0"/></division>
            <speech id="s3" #{chair} time="13:20:00" url="x"><p>The question now is that this bill be now read a second time.</p></speech>
            <division divdate="DATE" divnumber="2" id="d2" time="13:21:00" url="x">#{bills}<divisioncount ayes="26" noes="15" pairs="0" tellerayes="0" tellernoes="0"/></division>
          XML
        end

        def guillotined(number, time)
          described_class.build({ id: number, house: "senate", date: "2026-08-20", number: number, clock_time: time },
                                xml_content: guillotine_xml)
        end

        it "carries the chair's own sentence saying the time had expired, and warns there was no further debate" do
          packet = guillotined(2, "1:21 PM")

          expect(packet.limitation_statement).to include(
            id: "s2", speaker: "Casey Whitlow", time: "13:15:00",
            text: "Pursuant to order agreed on 18 August 2026, the time allotted for consideration of 2 bills has expired."
          )
          expect(packet.context_warnings.join).to include("under a limitation of debate")
        end

        it "credits the amendment's mover from the second reading debate when the chair names them" do
          packet = guillotined(1, "1:19 PM")

          expect(packet.mover.speech[:id]).to eq("s1")
          expect(packet.mover.found_by).to eq(:chair_named)
          expect(packet.transcript.prompt_text).to include("the Senate rejects the bill")
          expect(packet.context_warnings.join).to include("another stage of the same bill")
        end

        # The second reading question names nobody, and the amendment is a different question.
        it "leaves the second reading debate's move out of a question that does not name its mover" do
          packet = guillotined(2, "1:21 PM")

          expect(packet.mover).to be_nil
          expect(packet.transcript.prompt_text).not_to include("the Senate rejects the bill")
        end
      end
    end
  end
end
