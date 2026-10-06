# frozen_string_literal: true

require "spec_helper"
require_relative "../../../app/services/division_summary_pipeline/context_builder"

describe DivisionSummaryPipeline::ProvenanceValidator do
  describe ".validate" do
    let(:hansard_context) do
      <<~TEXT
        DEBATE: Consumer Data Right Reform
        SPEECH: Priya Nakamura:
        many small retailers still lack the technical systems needed to comply with the proposed timeframe.
        consumers should be given a longer transition period before new data-sharing obligations take effect.
      TEXT
    end

    let(:context_packet) do
      DivisionSummaryPipeline::ContextPacket.new(
        division_id: 2788,
        date: "2026-08-18",
        house: "representatives",
        clock_time: "12:39 PM",
        speaker_question: "The question is that the amendment be agreed to.",
        hansard_context: hansard_context
      )
    end

    it "validates successfully when evidence quotes exist verbatim in source text" do
      extraction = DivisionSummaryPipeline::ExtractionPayload.new(
        template_id: 2,
        topic: "Consumer Data Right Reform",
        motion_text: "That all words after 'That' be omitted",
        declines_second_reading: true,
        mover_claims: [
          DivisionSummaryPipeline::ClaimEvidence.new(
            claim: "Small retailers are not yet ready to comply",
            evidence: "many small retailers still lack the technical systems needed to comply with the proposed timeframe",
            speaker: "Priya Nakamura"
          )
        ]
      )

      result = described_class.validate(extraction, context_packet)
      expect(result.is_valid).to be(true)
      expect(result.errors).to be_empty
    end

    it "rejects claims where evidence is hallucinated and not found in source text" do
      extraction = DivisionSummaryPipeline::ExtractionPayload.new(
        template_id: 2,
        topic: "Consumer Data Right Reform",
        motion_text: "That all words after 'That' be omitted",
        declines_second_reading: true,
        mover_claims: [
          DivisionSummaryPipeline::ClaimEvidence.new(
            claim: "Hallucinated claim about taxation",
            evidence: "this legislation will introduce a forty percent tax on data brokers",
            speaker: "Priya Nakamura"
          )
        ]
      )

      result = described_class.validate(extraction, context_packet)
      expect(result.is_valid).to be(false)
      expect(result.errors.first).to include("Provenance check failed")
      expect(result.requires_human_review).to be(true)
    end

    it "rejects a long quote with a fabricated middle even when its start and end are genuine" do
      extraction = DivisionSummaryPipeline::ExtractionPayload.new(
        template_id: 2,
        topic: "Consumer Data Right Reform",
        motion_text: "That all words after 'That' be omitted",
        declines_second_reading: true,
        mover_claims: [
          DivisionSummaryPipeline::ClaimEvidence.new(
            claim: "Fabricated middle spliced between two genuine phrases",
            evidence: "many small retailers still lack the technical systems needed to secretly triple " \
                      "the levy on regional co-operatives before new data-sharing obligations take effect",
            speaker: "Priya Nakamura"
          )
        ]
      )

      result = described_class.validate(extraction, context_packet)
      expect(result.is_valid).to be(false)
      expect(result.errors.first).to include("Provenance check failed")
    end

    it "rejects a genuine quote attributed to a speaker who did not say it" do
      extraction = DivisionSummaryPipeline::ExtractionPayload.new(
        template_id: 2,
        topic: "Consumer Data Right Reform",
        motion_text: "That all words after 'That' be omitted",
        declines_second_reading: true,
        mover_claims: [
          DivisionSummaryPipeline::ClaimEvidence.new(
            claim: "Small retailers are not yet ready to comply",
            evidence: "many small retailers still lack the technical systems needed to comply with the proposed timeframe",
            speaker: "Jordan McAllister"
          )
        ]
      )

      result = described_class.validate(extraction, context_packet)
      expect(result.is_valid).to be(false)
      expect(result.errors.first).to include("Provenance check failed")
      expect(result.errors.first).to include("attributed to 'Jordan McAllister'")
    end

    it "still validates evidence with no speaker attribution against the whole context" do
      extraction = DivisionSummaryPipeline::ExtractionPayload.new(
        template_id: 2,
        topic: "Consumer Data Right Reform",
        motion_text: "That all words after 'That' be omitted",
        declines_second_reading: true,
        mover_claims: [
          DivisionSummaryPipeline::ClaimEvidence.new(
            claim: "Small retailers are not yet ready to comply",
            evidence: "many small retailers still lack the technical systems needed to comply with the proposed timeframe",
            speaker: nil
          )
        ]
      )

      result = described_class.validate(extraction, context_packet)
      expect(result.is_valid).to be(true)
    end

    context "with more than one speaker in the transcript" do
      let(:hansard_context) do
        <<~TEXT
          DEBATE: Consumer Data Right Reform
          SPEECH: Priya Nakamura:
          many small retailers still lack the technical systems needed to comply with the proposed timeframe.
          SPEECH: Jordan McAllister:
          the opposition will not stand in the way of stronger privacy protections for consumers.
        TEXT
      end

      it "verifies evidence against only the claimed speaker's own lines" do
        extraction = DivisionSummaryPipeline::ExtractionPayload.new(
          template_id: 2,
          topic: "Consumer Data Right Reform",
          motion_text: "That all words after 'That' be omitted",
          declines_second_reading: true,
          mover_claims: [
            DivisionSummaryPipeline::ClaimEvidence.new(
              claim: "The opposition supports stronger privacy protections",
              evidence: "the opposition will not stand in the way of stronger privacy protections for consumers",
              speaker: "Jordan McAllister"
            )
          ]
        )

        result = described_class.validate(extraction, context_packet)
        expect(result.is_valid).to be(true)
      end

      it "rejects a quote from one speaker credited to the other" do
        extraction = DivisionSummaryPipeline::ExtractionPayload.new(
          template_id: 2,
          topic: "Consumer Data Right Reform",
          motion_text: "That all words after 'That' be omitted",
          declines_second_reading: true,
          mover_claims: [
            DivisionSummaryPipeline::ClaimEvidence.new(
              claim: "The opposition supports stronger privacy protections",
              evidence: "the opposition will not stand in the way of stronger privacy protections for consumers",
              speaker: "Priya Nakamura"
            )
          ]
        )

        result = described_class.validate(extraction, context_packet)
        expect(result.is_valid).to be(false)
        expect(result.errors.first).to include("Provenance check failed")
      end

      it "matches speaker when the extracted attribution includes an honorific like Mr or Senator" do
        extraction = DivisionSummaryPipeline::ExtractionPayload.new(
          template_id: 2,
          topic: "Consumer Data Right Reform",
          motion_text: "That all words after 'That' be omitted",
          declines_second_reading: true,
          mover_claims: [
            DivisionSummaryPipeline::ClaimEvidence.new(
              claim: "The opposition supports stronger privacy protections",
              evidence: "the opposition will not stand in the way of stronger privacy protections for consumers",
              speaker: "Mr McAllister"
            )
          ]
        )

        result = described_class.validate(extraction, context_packet)
        expect(result.is_valid).to be(true)
      end
    end

    context "when hansard_context has no per-speaker SPEECH: tagging (Hansard XML fallback)" do
      let(:hansard_context) do
        <<~TEXT
          DEBATE: Consumer Data Right Reform

          MOTION:
          many small retailers still lack the technical systems needed to comply with the proposed timeframe.
        TEXT
      end

      it "still verifies evidence against the whole context regardless of the claimed speaker" do
        extraction = DivisionSummaryPipeline::ExtractionPayload.new(
          template_id: 2,
          topic: "Consumer Data Right Reform",
          motion_text: "That all words after 'That' be omitted",
          declines_second_reading: true,
          mover_claims: [
            DivisionSummaryPipeline::ClaimEvidence.new(
              claim: "Small retailers are not yet ready to comply",
              evidence: "many small retailers still lack the technical systems needed to comply with the proposed timeframe",
              speaker: "Priya Nakamura"
            )
          ]
        )

        result = described_class.validate(extraction, context_packet)
        expect(result.is_valid).to be(true)
      end
    end

    it "enforces template 2 declines_second_reading boolean requirement" do
      extraction = DivisionSummaryPipeline::ExtractionPayload.new(
        template_id: 2,
        topic: "Consumer Data Right Reform",
        motion_text: "That all words after 'That' be omitted",
        declines_second_reading: nil
      )

      result = described_class.validate(extraction, context_packet)
      expect(result.is_valid).to be(false)
      expect(result.errors).to include("Template 2 requires 'declines_second_reading' to be explicitly boolean (true or false).")
    end

    describe "template-specific extracted fields" do
      let(:hansard_context) do
        <<~TEXT
          DEBATE: Selection of Bills Committee Report
          SPEECH: Jordan McAllister:
          I move that the matter be referred to the Selection of Bills Committee for inquiry and report.
          SPEECH: Jordan McAllister:
          That the honourable member for Brightwater be no longer heard.
          SPEECH: Jordan McAllister:
          That the Customs Regulation 2026 be disallowed.
          That the nuclear safety business be withdrawn from the Notice Paper.
          take the bill into consideration in detail at a later hour
        TEXT
      end

      let(:context_packet) do
        DivisionSummaryPipeline::ContextPacket.new(
          division_id: 2788,
          date: "2026-08-19",
          house: "representatives",
          clock_time: "12:39 PM",
          speaker_question: "The question is that the motion be agreed to.",
          hansard_context: hansard_context
        )
      end

      def extraction_with(fields)
        DivisionSummaryPipeline::ExtractionPayload.new(
          template_id: 13,
          topic: "budget estimates",
          motion_text: "That the matter be referred to the Selection of Bills Committee for inquiry and report.", **fields
        )
      end

      it "accepts template 13 when the committee name is extracted and verifiable" do
        result = described_class.validate(extraction_with(committee_name: "Selection of Bills Committee"), context_packet)
        expect(result.is_valid).to be(true)
        expect(result.errors).to be_empty
      end

      it "rejects template 13 when the committee name is missing so a blank is never published" do
        result = described_class.validate(extraction_with({}), context_packet)
        expect(result.is_valid).to be(false)
        expect(result.errors.join).to include("committee_name")
        expect(result.requires_human_review).to be(true)
      end

      it "rejects an extracted fact that does not appear in the Hansard source" do
        result = described_class.validate(extraction_with(committee_name: "Committee for Made-up Affairs"), context_packet)
        expect(result.errors.join).to include("Provenance check failed")
      end

      it "requires template 23 to identify the targeted member by name or electorate" do
        extraction = DivisionSummaryPipeline::ExtractionPayload.new(
          template_id: 23,
          topic: "closure",
          motion_text: "That the honourable member for Brightwater be no longer heard."
        )

        result = described_class.validate(extraction, context_packet)
        expect(result.is_valid).to be(false)
        expect(result.errors.join).to include("target_name")
      end

      it "accepts template 23 when the electorate is stated verbatim" do
        extraction = DivisionSummaryPipeline::ExtractionPayload.new(
          template_id: 23,
          topic: "closure",
          motion_text: "That the honourable member for Brightwater be no longer heard.",
          target_electorate: "Brightwater"
        )

        result = described_class.validate(extraction, context_packet)
        expect(result.is_valid).to be(true)
      end

      it "requires each other template's specific fact before that template passes validation" do
        template_9 = described_class.validate(
          DivisionSummaryPipeline::ExtractionPayload.new(template_id: 9, topic: "customs", motion_text: "That the Customs Regulation 2026 be disallowed."),
          context_packet
        )
        template_10 = described_class.validate(
          DivisionSummaryPipeline::ExtractionPayload.new(template_id: 10, topic: "conduct", motion_text: "That the minister be censured."),
          context_packet
        )
        template_19 = described_class.validate(
          DivisionSummaryPipeline::ExtractionPayload.new(template_id: 19, topic: "business", motion_text: "That the bill be considered in detail at a later hour."),
          context_packet
        )
        template_20 = described_class.validate(
          DivisionSummaryPipeline::ExtractionPayload.new(template_id: 20, topic: "business", motion_text: "That the nuclear safety business be withdrawn from the Notice Paper."),
          context_packet
        )

        expect(template_9.errors.join).to include("regulation_name")
        expect(template_10.errors.join).to include("target_name")
        expect(template_19.errors.join).to include("rearrangement_description")
        expect(template_20.errors.join).to include("business_name")
      end
    end

    describe "the procedural router's fence" do
      def packet_with(decision)
        DivisionSummaryPipeline::ContextPacket.new(
          division_id: 2788,
          date: "2026-08-18",
          house: "representatives",
          clock_time: "12:39 PM",
          speaker_question: "The question is that the amendment be agreed to.",
          hansard_context: "DEBATE: Housing Affordability Measures Bill",
          procedural_decision: decision
        )
      end

      def extraction_for(template_id)
        DivisionSummaryPipeline::ExtractionPayload.new(
          template_id: template_id,
          topic: "Housing Affordability Measures",
          motion_text: "That the amendment be agreed to.",
          declines_second_reading: false
        )
      end

      it "rejects a template the router locked out" do
        decision = DivisionSummaryPipeline::ProceduralRouter.route(
          speaker_question: "The question is that the amendment be agreed to.",
          chamber: "representatives",
          debate_heading: "Limitation of Debate"
        )
        expect(decision.locked_out_templates).to include(18)

        result = described_class.validate(extraction_for(18), packet_with(decision))

        expect(result.is_valid).to be(false)
        expect(result.errors.join).to include("locked out")
        expect(result.requires_human_review).to be(true)
      end

      it "accepts a template from the candidates the router fenced the extractor to" do
        decision = DivisionSummaryPipeline::ProceduralRouter.route(
          speaker_question: "The question is that the amendment be agreed to.",
          chamber: "representatives",
          debate_heading: "Limitation of Debate"
        )

        result = described_class.validate(extraction_for(2), packet_with(decision))

        expect(result.errors).to be_empty
      end

      it "rejects a template outside the candidates the router fenced the extractor to" do
        decision = DivisionSummaryPipeline::ProceduralRouter.route(
          speaker_question: "The question is that the bill be read a second time.",
          chamber: "representatives"
        )
        expect(decision.candidate_templates).to contain_exactly(2, 6)

        result = described_class.validate(extraction_for(15), packet_with(decision))

        expect(result.is_valid).to be(false)
        expect(result.errors.join).to include("outside the candidates")
      end

      # Reaching the general-motion fallback means no rule matched, so its single candidate
      # is a default rather than evidence about the question. An extractor that recognises
      # the motion is better informed than the default and is left to say so.
      it "allows any template when the router fell through to the general motion fallback" do
        decision = DivisionSummaryPipeline::ProceduralRouter.route(
          speaker_question: "The question is that this House notes the report.",
          chamber: "representatives"
        )
        expect(decision.rule_name).to eq("GENERAL_MOTION_FALLBACK")

        result = described_class.validate(extraction_for(17), packet_with(decision))

        expect(result.errors).to be_empty
      end

      it "skips the check when no routing decision reached the validator" do
        result = described_class.validate(extraction_for(15), packet_with(nil))

        expect(result.errors).to be_empty
      end
    end

    # House Guide pp. 68-69 gives a closed list of reasoned-amendment forms, and two of them
    # read as declining until the negation is noticed. Template 2 publishes the opposite
    # sentence depending on the flag, so a flag that disagrees with the motion text the model
    # itself returned is caught mechanically rather than trusted (KNOWN_ISSUES.md, KI-11).
    describe "declines_second_reading against the motion text" do
      def template_2_extraction(motion_text, declines)
        DivisionSummaryPipeline::ExtractionPayload.new(
          template_id: 2,
          topic: "Example Bill 2026",
          motion_text: motion_text,
          declines_second_reading: declines,
          mover_claims: []
        )
      end

      it "rejects a true flag on a 'whilst not declining' amendment" do
        extraction = template_2_extraction(
          "That all words after \"That\" be omitted with a view to substituting: \"whilst not declining to " \
          "give the bill a second reading, the House is of the opinion that ...\"", true
        )

        result = described_class.validate(extraction, nil)

        expect(result.errors.join).to include("whilst not declining/opposing")
        expect(result.is_valid).to be(false)
      end

      it "rejects a true flag on a 'whilst not opposing' amendment" do
        extraction = template_2_extraction(
          "That all words after \"That\" be omitted: \"whilst not opposing the provisions of the bill, the " \
          "House is of the opinion that ...\"", true
        )

        result = described_class.validate(extraction, nil)

        expect(result.is_valid).to be(false)
      end

      it "rejects a false flag on an amendment that declines the second reading" do
        extraction = template_2_extraction(
          "That all words after \"That\" be omitted: \"the House declines to give the bill a second reading " \
          "as it is of the opinion that ...\"", false
        )

        result = described_class.validate(extraction, nil)

        expect(result.errors.join).to include("declines to give the bill a second reading")
        expect(result.is_valid).to be(false)
      end

      it "accepts a true flag on an amendment that does decline the second reading" do
        extraction = template_2_extraction(
          "That all words after \"That\" be omitted: \"the House declines to give the bill a second reading\"", true
        )

        result = described_class.validate(extraction, nil)

        expect(result.errors).to be_empty
      end

      it "accepts a false flag on a 'whilst not declining' amendment" do
        extraction = template_2_extraction(
          "That all words after \"That\" be omitted: \"whilst not declining to give the bill a second reading, " \
          "the House is of the opinion that ...\"", false
        )

        result = described_class.validate(extraction, nil)

        expect(result.errors).to be_empty
      end
    end

    # Stage 1 can tell when the debate beside a division may not be about it. Carrying those
    # flags through to the draft is the point; they are invisible to a reviewer otherwise.
    describe "context warnings from stage 1" do
      it "records them as warnings and sends the draft to human review" do
        packet = DivisionSummaryPipeline::ContextPacket.new(
          hansard_context: "DEBATE: Bills\n\nSPEECH: Fictional Member:\nnothing relevant",
          context_warnings: ["This division immediately follows another with no debate between them."]
        )
        extraction = DivisionSummaryPipeline::ExtractionPayload.new(
          template_id: 22, topic: "Closure", motion_text: "That the question be now put."
        )

        result = described_class.validate(extraction, packet)

        expect(result.is_valid).to be(true)
        expect(result.warnings.join).to include("Context warning: This division immediately follows another")
        expect(result.requires_human_review).to be(true)
      end

      it "leaves a packet with no warnings alone" do
        packet = DivisionSummaryPipeline::ContextPacket.new(
          hansard_context: "DEBATE: Bills\n\nSPEECH: Fictional Member:\nThat the question be now put.",
          context_warnings: []
        )
        extraction = DivisionSummaryPipeline::ExtractionPayload.new(
          template_id: 22, topic: "Closure", motion_text: "That the question be now put."
        )

        result = described_class.validate(extraction, packet)

        expect(result.requires_human_review).to be(false)
      end
    end
  end
end
