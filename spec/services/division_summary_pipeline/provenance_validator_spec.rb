# frozen_string_literal: true

require "spec_helper"

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
  end
end

