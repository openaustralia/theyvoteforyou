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

      # House S.O. 133 as at 23 July 2025 has no Tuesday rule: the matter of public importance
      # window once used here came from the guide, and was a rule about quorum counts (S.O. 55(c)).
      # 25 August 2026 is a Tuesday.
      it "does not warn about a Tuesday afternoon, which S.O. 133 no longer defers to" do
        division_data = { id: 1056, house: "representatives", name: "Closure of Debate", date: "2026-08-25",
                          number: 1, clock_time: "4:15 PM" }

        packet = described_class.build(division_data, xml_content: parlparse_xml)

        expect(packet.context_warnings.join).not_to include("Standing Order 133")
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

      # KI-50: as at Senate 18 August 2026 #2, the order setting the week's
      # hours and guillotines, whose first paragraph Hansard sets as "That—" alone.
      it "routes a motion whose first paragraph is only \"That\" on the paragraphs after it" do
        xml = debates("2026-08-18", <<~XML)
          <minor-heading id="h2" url="x">Business; Rearrangement</minor-heading>
          <speech id="s1" speakerid="uk.org.publicwhip/lord/900101" speakername="Morgan Treloar" time="12:13:00" url="x"><p>I move:</p><p class="italic">That—</p><p class="italic">(1) On Tuesday, 18 August 2026:</p><p class="italic">(a) the hours of meeting be midday till adjournment; and</p><p class="italic">(b) the question on the second reading of the Example Bill 2026 be put immediately.</p><p class="italic">(2) Paragraph 1(b) operates as a limitation of debate under standing order 142.</p></speech>
          <speech id="s2" speakerid="uk.org.publicwhip/lord/900102" speakername="Casey Whitlow" time="12:14:00" url="x"><p>The question is that the motion be agreed to.</p></speech>
          #{division_element(2, '12:15:00')}
        XML
        packet = described_class.build({ id: 1, house: "senate", date: "2026-08-18", number: 2, clock_time: "12:15 PM" },
                                       xml_content: xml)

        expect(packet.routing.allowed_templates).to eq([18])
        expect(packet.routing).to be_advisory
      end

      # KI-55: as at Senate 12 August 2026 #4, a matter of urgency one senator
      # proposed and another moved.
      it "finds who proposed a matter of urgency someone else moved" do
        create(:member, person: create(:person), gid: "uk.org.publicwhip/lord/900150", first_name: "Morgan", last_name: "Treloar",
                        constituency: "Tasmania", party: "Example Party", house: "senate",
                        entered_house: "2020-01-01", left_house: "9999-12-31")
        xml = debates("2026-08-12", <<~XML)
          <minor-heading id="h2" url="x">Matters of Urgency; Example Levy</minor-heading>
          <speech id="s1" speakerid="uk.org.publicwhip/lord/900102" speakername="Casey Whitlow" time="15:30:00" url="x"><p>Senator Treloar has submitted a proposal, under standing order 75, today, which has been circulated:</p><p class="italic">That, in the opinion of the Senate, the following is a matter of urgency: The need for a fairer levy.</p></speech>
          <speech id="s2" speakerid="uk.org.publicwhip/lord/900103" speakername="Sam Okafor" time="15:31:00" url="x"><p>I move:</p><p class="italic">That, in the opinion of the Senate, the following is a matter of urgency: The need for a fairer levy.</p></speech>
          <speech id="s3" speakerid="uk.org.publicwhip/lord/900102" speakername="Casey Whitlow" time="16:29:00" url="x"><p>The question is that Senator Treloar's motion, as moved by Senator Okafor, be agreed to.</p></speech>
          #{division_element(4, '16:30:00')}
        XML
        packet = described_class.build({ id: 4, house: "senate", date: "2026-08-12", number: 4, clock_time: "4:30 PM" },
                                       xml_content: xml)

        expect(packet.mover.speech[:speaker]).to eq("Sam Okafor")
        expect(packet.proposer.name).to eq("Morgan Treloar")
      end

      # KI-54: as at Senate 13 August 2026 #7, a minister's closure of a
      # suspension debate, followed straight away by the suspension itself.
      context "with a closure" do
        let(:closure_xml) do
          debates("2026-08-13", <<~XML)
            <minor-heading id="h2" url="x">Business; Consideration of Legislation</minor-heading>
            <speech id="s1" speakerid="uk.org.publicwhip/lord/900101" speakername="Morgan Treloar" time="12:15:00" url="x"><p>I move:</p><p class="italic">That so much of the standing orders be suspended as would prevent me moving a motion to give precedence to the Example Bill 2026.</p></speech>
            <speech id="s2" speakerid="uk.org.publicwhip/lord/900103" speakername="Sam Okafor" time="12:20:00" url="x"><p>We oppose this suspension.</p></speech>
            <speech id="s3" speakerid="uk.org.publicwhip/lord/900104" speakername="Jo Marlowe" time="12:25:00" url="x"><p>I move:</p><p class="italic">That the question be now put.</p></speech>
            <speech id="s4" speakerid="uk.org.publicwhip/lord/900102" speakername="Casey Whitlow" time="12:26:00" url="x"><p>The question is that the motion by Minister Marlowe to close this suspension debate be agreed to.</p></speech>
            #{division_element(7, '12:31:00')}
            <speech id="s5" speakerid="uk.org.publicwhip/lord/900102" speakername="Casey Whitlow" time="12:36:00" url="x"><p>The question now is that the suspension motion moved by Senator Treloar be agreed to.</p></speech>
            #{division_element(8, '12:37:00')}
          XML
        end

        it "finds what the closure cut short, and links the division that then put it" do
          create(:division, house: "senate", date: Date.new(2026, 8, 13), number: 8)
          packet = described_class.build({ id: 7, house: "senate", date: "2026-08-13", number: 7, clock_time: "12:31 PM" },
                                         xml_content: closure_xml)

          expect(packet.mover.speech[:speaker]).to eq("Jo Marlowe")
          expect(packet.closed_template_id).to eq(17)
          expect(packet.facts[:followup_link]).to eq("/divisions/senate/2026-08-13/8")
        end

        it "links nothing when the next division is not in the database" do
          packet = described_class.build({ id: 7, house: "senate", date: "2026-08-13", number: 7, clock_time: "12:31 PM" },
                                         xml_content: closure_xml)

          expect(packet.facts[:followup_link]).to be_nil
        end
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

      # As on 18 August 2026, when the second reading's time expired and the chair put the
      # opposition's amendment, then eight amendments the Greens had circulated, then the second
      # reading itself, all under the "; Second Reading" heading the minister moved it under.
      context "when the chair puts amendments nobody moved in the chamber" do
        let(:chair) { "speakerid=\"uk.org.publicwhip/lord/900102\" speakername=\"Casey Whitlow\"" }
        let(:circulated_xml) do
          debates("2026-08-18", <<~XML)
            <minor-heading id="h2" url="x">Example Bill 2026; Second Reading</minor-heading>
            <speech id="s1" speakerid="uk.org.publicwhip/lord/900103" speakername="Jo Marlowe" time="11:00:00" url="x"><p>I table a revised explanatory memorandum relating to the bill and move:</p><p class="italic">That this bill be now read a second time.</p><p>This bill makes the scheme fairer.</p></speech>
            <speech id="s2" #{chair} time="12:18:00" url="x"><p>Pursuant to order, the time allotted for the second reading of this bill has expired. The question is that the opposition amendment on sheet 9100 be agreed to.</p></speech>
            #{division_element(1, '12:20:00')}
            <speech id="s3" #{chair} time="12:25:00" url="x"><p>I will now deal with the amendments circulated by the Example Party. The question is that the amendments on sheets 9101 and 9102 be agreed to.</p><p class="italic">Example Party's circulated amendments—</p><p class="italic">Omit all words after "That", substitute "the Senate rejects the bill and calls on the Government to await the report of the Select Committee on Example Services before appropriate alternatives are established".</p><p class="italic">Omit all words after "That", substitute "the Senate rejects the bill and calls on the Government to withdraw it".</p></speech>
            #{division_element(2, '12:27:00')}
            <speech id="s4" #{chair} time="12:29:00" url="x"><p>I will now deal with the amendment circulated by Senator Treloar. The question is that the amendment on sheet 9103 be agreed to.</p><p class="italic">At the end of the motion, add ", but the Senate notes the cost".</p></speech>
            #{division_element(3, '12:30:00')}
            <speech id="s5" #{chair} time="12:34:00" url="x"><p>The question is that the bill now be read a second time.</p></speech>
            #{division_element(4, '12:35:00')}
          XML
        end

        def circulated(number)
          described_class.build({ id: number, house: "senate", date: "2026-08-18", number: number, clock_time: "12:27 PM" },
                                xml_content: circulated_xml)
        end

        it "routes on the question alone, not the lead-in saying the time allotted has expired" do
          expect(circulated(1).routing.template_id).to eq(2)
        end

        it "routes on the question alone, not the amendments printed after it, and credits nobody with moving them" do
          packet = circulated(2)

          expect(packet.speaker_question).to eq("The question is that the amendments on sheets 9101 and 9102 be agreed to.")
          expect(packet.routing).to be_deterministic
          expect(packet.routing.template_id).to eq(2)
          expect(packet.question_speech.label).to eq("Casey Whitlow")
          expect(packet.mover).to be_nil
        end

        # KI-44: nobody moved them, so the chair's statement is the only place
        # their terms are recorded, and a model asked to find them listed about 140 paragraph IDs.
        it "takes the amendments the chair put as the terms, found by rule, and says nobody moved them" do
          packet = circulated(2)

          expect(packet).to be_motion_found
          expect(packet.transcript.question_terms_units.map(&:text).first).to eq("Example Party's circulated amendments—")
          expect(packet.transcript.question_terms_units.size).to eq(3)
          expect(packet.circulation).to have_attributes(by: "the Example Party", member: nil, plural: true)
        end

        # As at Senate 18 August 2026 #16, where the terms' sheet headings are in plain type.
        it "keeps the plain headings Hansard sets among the amendments, and stops at the next question decided" do
          xml = debates("2026-08-18", <<~XML)
            <minor-heading id="h2" url="x">Example Bill 2026; In Committee</minor-heading>
            <speech id="s1" #{chair} time="20:16:00" url="x"><p>The question now is that amendments (1) to (4) on sheet XY101 be agreed to.</p><p class="italic">(1) Clause 2, page 2 (table item 3), omit the item.</p><p>Question agreed to.</p><p>I will now deal with the remaining amendments circulated by the Example Party. The first question is that part 3 of schedule 1 stand as printed.</p><p>SHEET 9201</p><p class="italic">(2) Schedule 1, Part 3, page 12 (line 1) to page 14 (line 9), to be opposed.</p><p>SHEET 9202</p><p class="italic">(4) Schedule 1, item 7, page 15 (lines 1 to 6), to be opposed.</p></speech>
            #{division_element(1, '20:17:00')}
          XML
          packet = described_class.build({ id: 1, house: "senate", date: "2026-08-18", number: 1, clock_time: "8:17 PM" },
                                         xml_content: xml)

          expect(packet.routing.allowed_templates).to eq([28])
          expect(packet.transcript.question_terms_units.map(&:text))
            .to eq(["SHEET 9201", "(2) Schedule 1, Part 3, page 12 (line 1) to page 14 (line 9), to be opposed.", "SHEET 9202",
                    "(4) Schedule 1, item 7, page 15 (lines 1 to 6), to be opposed."])
        end

        # The chair's run of questions on the amendments does not separate the second reading
        # question from the move it puts.
        it "still credits the second reading to the minister who moved it" do
          expect(circulated(4).mover.speech[:speaker]).to eq("Jo Marlowe")
        end
      end
    end
  end
end
