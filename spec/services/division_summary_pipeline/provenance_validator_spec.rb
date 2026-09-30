# frozen_string_literal: true

require "spec_helper"
require "nokogiri"

# Fictional members, bills and motions in the shape current ParlParse XML has.
describe DivisionSummaryPipeline::ProvenanceValidator do
  let(:motion_paragraph) do
    "<p class=\"italic\">At the end of the motion, add \", but the Senate calls on the Government to refer the " \
      "scheme to the Economics References Committee\".</p>"
  end
  let(:mover_speech) do
    summary_speech(<<~XML, id: "s1", name: "Morgan Treloar", gid: "uk.org.publicwhip/lord/900001", time: "13:20")
      <p>Rural students pay more to study. The Economics References Committee has not looked at it.</p>
      <p>I move the second reading amendment on sheet 9001:</p>
      #{motion_paragraph}
      <p>The Senate should support it.</p>
    XML
  end
  let(:other_speech) do
    summary_speech("<p>I oppose this amendment. It is poorly drafted.</p>",
                   id: "s2", name: "Alex Pemberton", gid: "uk.org.publicwhip/lord/900003", time: "13:25")
  end
  let(:question) { "The question is that the second reading amendment moved by Senator Treloar on sheet 9001 be agreed to." }
  let(:chair_speech) do
    summary_speech("<p>#{question}</p>", id: "s3", name: "Robin Castellan", gid: "uk.org.publicwhip/lord/900002", time: "13:30")
  end
  let(:speeches) { [mover_speech, other_speech, chair_speech] }
  let(:routing) { DivisionSummaryPipeline::RoutingDecision.fenced([2, 29], rule_name: "SECOND_READING_NUANCE", reason: "test") }

  def packet(speeches: self.speeches, question: self.question, routing: self.routing, warnings: [])
    summary_packet(speeches: speeches, question: question, routing: routing, warnings: warnings)
  end

  def extraction(template_id: 2, declines: false, explanation: %w[S1.1], motion: [], facts: {}, missing: [])
    DivisionSummaryPipeline::ExtractionPayload.from_h(
      "interpretation" => { "template_id" => template_id, "declines_second_reading" => declines, "missing" => missing },
      "references" => { "explanation" => explanation, "motion" => motion, "facts" => facts }
    )
  end

  def validate(payload = extraction, context = packet)
    described_class.validate(payload, context)
  end

  describe "the evidence a valid draft quotes" do
    it "takes the motion, its introduction and the chair's question from Stage 1, each as Hansard recorded it" do
      evidence = validate.evidence

      expect(evidence.introduction.text).to eq("I move the second reading amendment on sheet 9001:")
      expect(evidence.motion.text).to start_with("At the end of the motion, add \", but the Senate calls on")
      expect(evidence.motion.found_by).to eq(:rule)
      expect(evidence.question).to have_attributes(text: question, speaker: "Robin Castellan", time: "13:30")
      expect(evidence.limitation).to be_nil
    end

    # Stage 1 finds it outside the transcript, since the rest of the chair's statement usually
    # puts a question on another bill, so there is nothing for the model to point at.
    it "takes the chair's sentence saying a limitation of debate's time had expired from Stage 1" do
      statement = { id: "s0", speaker: "Robin Castellan", speaker_gid: "uk.org.publicwhip/lord/900002", time: "13:15",
                    text: "Pursuant to order, the time allotted for this bill has expired." }
      context = summary_packet(speeches: speeches, question: question, routing: routing, limitation_statement: statement)

      expect(validate(extraction, context).evidence.limitation).to have_attributes(
        text: "Pursuant to order, the time allotted for this bill has expired.", speaker: "Robin Castellan", time: "13:15",
        unit_ids: [], found_by: :rule
      )
    end

    it "turns the model's sentence IDs into the mover's exact words, joining consecutive ones" do
      result = validate(extraction(explanation: %w[S1.2 S1.1]))

      expect(result).to be_valid
      expect(result.evidence.explanations.map(&:text))
        .to eq(["Rural students pay more to study. The Economics References Committee has not looked at it."])
      expect(result.evidence.explanations.first).to have_attributes(speaker: "Morgan Treloar", time: "13:20", found_by: :model)
    end

    it "keeps separate passages separate" do
      expect(validate(extraction(explanation: %w[S1.1 S1.5])).evidence.explanations.map(&:text))
        .to eq(["Rural students pay more to study.", "The Senate should support it."])
    end
  end

  # An explanation is only ever the mover's own words, never the motion restated in them.
  describe "explanation references that do not hold up" do
    it "drops a reference to the motion itself, so the draft says no explanation was recorded" do
      result = validate(extraction(explanation: %w[S1.4]))

      expect(result).to be_valid
      expect(result.evidence.explanations).to be_empty
      expect(result.warnings.join).to include("S1.4 is motion text, not the mover's own words")
    end

    # KNOWN_ISSUES.md KI-38: every model tried on a real division picked a minister's old words that
    # a senator had quoted, and the draft printed them as the senator's explanation.
    context "when the mover quotes someone else" do
      let(:mover_speech) do
        summary_speech(<<~XML, id: "s1", name: "Morgan Treloar", gid: "uk.org.publicwhip/lord/900001", time: "13:20")
          <p>The minister told the Senate:</p>
          <p class="italic">Rural students pay no more to study.</p>
          <p>That is wrong.</p>
          <p>I move the second reading amendment on sheet 9001:</p>
          #{motion_paragraph}
        XML
      end

      it "drops the quoted words, so they are never printed as the mover's" do
        result = validate(extraction(explanation: %w[S1.2 S1.3]))

        expect(result).to be_valid
        expect(result.evidence.explanations.map(&:text)).to eq(["That is wrong."])
        expect(result.warnings.join).to include("S1.2 is quotation text, not the mover's own words")
      end
    end

    it "drops another member's sentence" do
      result = validate(extraction(explanation: %w[S2.1 S1.1]))

      expect(result.evidence.explanations.map(&:text)).to eq(["Rural students pay more to study."])
      expect(result.warnings.join).to include("S2.1 was spoken by Alex Pemberton, not the mover")
    end

    it "drops the chair's words and IDs that are not in the transcript" do
      result = validate(extraction(explanation: %w[S3.1 S9.9]))

      expect(result.evidence.explanations).to be_empty
      expect(result.warnings.join).to include("S3.1 is chair text", "S9.9 is not in the transcript")
    end

    it "quotes at most six sentences, the first ones spoken" do
      long = summary_speech("<p>#{(1..8).map { |n| "Point number #{n} stands." }.join(' ')}</p><p>I move:</p>#{motion_paragraph}",
                            id: "s1", name: "Morgan Treloar", gid: "uk.org.publicwhip/lord/900001", time: "13:20")
      ids = (1..8).map { |n| "S1.#{n}" }.reverse
      result = validate(extraction(explanation: ids), packet(speeches: [long, other_speech, chair_speech]))

      expect(result.evidence.explanations.first.text).to eq((1..6).map { |n| "Point number #{n} stands." }.join(" "))
      expect(result.warnings.join).to include("only the first 6")
    end

    it "ignores explanations for a template that prints none" do
      closure = DivisionSummaryPipeline::RoutingDecision.settled(22, rule_name: "CLOSURE_OF_DEBATE", reason: "test")
      result = validate(extraction(template_id: 22, explanation: %w[S1.1]), packet(routing: closure))

      expect(result.evidence.explanations).to be_empty
      expect(result.warnings.join).to include("template that prints none")
    end
  end

  describe "the operative motion" do
    let(:no_move) do
      summary_speech("<p>Rural students pay more to study.</p>", id: "s1", name: "Morgan Treloar",
                                                                 gid: "uk.org.publicwhip/lord/900001", time: "13:20")
    end

    it "is an error when the question only refers to a motion that is nowhere in the transcript" do
      result = validate(extraction(explanation: []), packet(speeches: [no_move, other_speech, chair_speech]))

      expect(result).not_to be_valid
      expect(result.errors.join).to include("The operative motion could not be found in Hansard")
    end

    it "is not needed when the question states its own terms, as a Speaker's adjournment does" do
      adjourn = "The question is that the Senate do now adjourn."
      closure = DivisionSummaryPipeline::RoutingDecision.settled(26, rule_name: "ADJOURNMENT_OF_CHAMBER", reason: "test")
      chair = summary_speech("<p>#{adjourn}</p>", id: "s3", name: "Robin Castellan", gid: "uk.org.publicwhip/lord/900002", time: "13:30")
      result = validate(extraction(template_id: 26, explanation: []),
                        packet(speeches: [no_move, chair], question: adjourn, routing: closure))

      expect(result).to be_valid
      expect(result.evidence.motion).to be_nil
    end

    it "can come from the model's paragraph IDs when Stage 1 found no move, as one unbroken passage" do
      record = DivisionSummaryPipeline::Transcript.from_record(heading: "Motions", text: "Debate on the scheme.\nThat the Senate notes the scheme.")
      context = packet.with(transcript: record, mover: nil)
      result = validate(extraction(explanation: [], motion: %w[S1.2]), context)

      expect(result.evidence.motion).to have_attributes(text: "That the Senate notes the scheme.", found_by: :model)
    end

    it "prefers Stage 1's motion over the model's, and says so" do
      result = validate(extraction(motion: %w[S1.5]))

      expect(result.evidence.motion.found_by).to eq(:rule)
      expect(result.warnings.join).to include("Stage 1 found the motion by rule")
    end
  end

  describe "facts a template names" do
    let(:referral) { DivisionSummaryPipeline::RoutingDecision.settled(13, rule_name: "COMMITTEE_REFERRAL", reason: "test") }

    it "resolves to Hansard's own text inside the unit the model named" do
      facts = { "committee_name" => { "unit" => "S1.4", "text" => "economics references committee" } }
      result = validate(extraction(template_id: 13, facts: facts), packet(routing: referral))

      expect(result).to be_valid
      expect(result.evidence.fact(:committee_name)).to eq("Economics References Committee")
    end

    it "is an error when a required fact is not in the unit named, even if it is elsewhere" do
      facts = { "committee_name" => { "unit" => "S1.5", "text" => "Economics References Committee" } }
      result = validate(extraction(template_id: 13, facts: facts), packet(routing: referral))

      expect(result.errors.join).to include("Template 13 requires 'committee_name'")
      expect(result.warnings.join).to include("is not in that unit")
    end

    it "accepts either the name or the electorate where a template needs one of them" do
      suspension = DivisionSummaryPipeline::RoutingDecision.settled(24, rule_name: "SUSPENSION_OF_MEMBER", reason: "test")

      expect(validate(extraction(template_id: 24, explanation: []), packet(routing: suspension)).errors.join)
        .to include("'target_name' or 'target_electorate'")
    end
  end

  describe "the template" do
    it "is an error outside the router's fence, and for a forbidden template" do
      guard = DivisionSummaryPipeline::RoutingDecision.fenced([2, 3], rule_name: "GUILLOTINE_TRAP_AVOIDED", reason: "test",
                                                                      forbidden: [18])

      expect(validate(extraction(template_id: 6), packet(routing: guard)).errors.join).to include("outside the allowed templates")
      expect(validate(extraction(template_id: 18), packet(routing: guard)).errors.join).to include("is forbidden")
    end

    it "may leave an advisory shortlist" do
      fallback = DivisionSummaryPipeline::RoutingDecision.default([15], rule_name: "GENERAL_MOTION_FALLBACK", reason: "test")

      expect(validate(extraction(template_id: 2), packet(routing: fallback))).to be_valid
    end

    it "is an error when it is not a catalogue template" do
      unknown = DivisionSummaryPipeline::TemplateCatalogue::IDS.max + 1

      expect(validate(extraction(template_id: unknown)).errors.join).to include("Invalid template_id #{unknown}")
    end
  end

  # KNOWN_ISSUES.md KI-11
  describe "declines_second_reading against the motion text" do
    it "is required for Template 2" do
      expect(validate(extraction(declines: nil)).errors.join).to include("requires 'declines_second_reading'")
    end

    it "cannot be true for a \"whilst not declining\" amendment" do
      whilst = summary_speech(<<~XML, id: "s1", name: "Morgan Treloar", gid: "uk.org.publicwhip/lord/900001", time: "13:20")
        <p>I move:</p>
        <p class="italic">That all words after "That" be omitted with a view to substituting "whilst not declining to give the bill a second reading, the Senate notes the scheme".</p>
      XML
      result = validate(extraction(declines: true, explanation: []), packet(speeches: [whilst, other_speech, chair_speech]))

      expect(result.errors.join).to include("\"whilst not declining/opposing\" form")
    end
  end

  describe "what a reviewer is told" do
    it "carries Stage 1's context warnings and the model's missing evidence as warnings" do
      result = validate(extraction(missing: ["mover_speech"]), packet(warnings: ["No debate speeches were found."]))

      expect(result).to be_valid
      expect(result).to be_requires_human_review
      expect(result.warnings).to include("Context warning: No debate speeches were found.")
      expect(result.warnings.join).to include("mover_speech")
    end

    it "fails cleanly when the reply could not be read" do
      result = described_class.validate(nil, packet)

      expect(result).not_to be_valid
      expect(result.evidence).to eq(DivisionSummaryPipeline::Evidence.empty)
    end
  end
end
