# frozen_string_literal: true

require "spec_helper"

describe DivisionSummaryPipeline::ExtractionPayload do
  describe ".from_json" do
    it "parses valid JSON into an ExtractionPayload instance" do
      json = <<~JSON
        {
          "template_id": 2,
          "topic": "Consumer Data Right Reform",
          "motion_text": "That all words after 'That' be omitted",
          "declines_second_reading": true,
          "mover_claims": [
            {
              "claim": "Small retailers are not yet ready to comply",
              "evidence": "small retailers are not yet ready to comply",
              "speaker": "Priya Nakamura"
            }
          ]
        }
      JSON

      payload = described_class.from_json(json)
      expect(payload).to be_present
      expect(payload.template_id).to eq(2)
      expect(payload.topic).to eq("Consumer Data Right Reform")
      expect(payload.declines_second_reading).to be(true)
      expect(payload.mover_claims.length).to eq(1)
      expect(payload.mover_claims.first.claim).to include("Small retailers")
    end

    it "strips markdown code fences" do
      json = <<~JSON
        ```json
        {
          "template_id": 22,
          "topic": "Border Processing Bill",
          "motion_text": "That the question be now put."
        }
        ```
      JSON

      payload = described_class.from_json(json)
      expect(payload).to be_present
      expect(payload.template_id).to eq(22)
      expect(payload.topic).to eq("Border Processing Bill")
    end

    it "handles legacy title and description payloads" do
      json = %({"title": "Motions - Cost of Living", "description": "Debate on cost of living."})
      payload = described_class.from_json(json)
      expect(payload).to be_legacy
      expect(payload.legacy_title).to eq("Motions - Cost of Living")
      expect(payload.legacy_description).to eq("Debate on cost of living.")
    end

    it "parses template-specific fields, stripping surrounding whitespace" do
      json = <<~JSON
        {
          "template_id": 23,
          "topic": "Closure",
          "motion_text": "That the honourable member for Brightwater be no longer heard.",
          "target_name": " Alex Downey ",
          "target_electorate": "Brightwater"
        }
      JSON

      payload = described_class.from_json(json)
      expect(payload.target_name).to eq("Alex Downey")
      expect(payload.target_electorate).to eq("Brightwater")
      expect(payload.committee_name).to be_nil
    end

    it "returns nil for invalid JSON" do
      expect(described_class.from_json("invalid json")).to be_nil
    end
  end

  # A false answer and no answer at all are different things here, and the coercion used to
  # collapse them: `!value.nil?` is true for `false`, so every supplied value became true.
  # Template 2's summary says the opposite thing depending on declines_second_reading, and a
  # false sufficient_context is the only trigger for the orchestrator's sitting-day retry.
  describe "boolean fields" do
    def payload_with(json)
      described_class.from_json(json)
    end

    it "keeps a false declines_second_reading false" do
      payload = payload_with('{"template_id": 2, "topic": "x", "motion_text": "y", "declines_second_reading": false}')

      expect(payload.declines_second_reading).to be(false)
    end

    it "keeps a true declines_second_reading true" do
      payload = payload_with('{"template_id": 2, "topic": "x", "motion_text": "y", "declines_second_reading": true}')

      expect(payload.declines_second_reading).to be(true)
    end

    it "leaves declines_second_reading nil when the model did not answer" do
      payload = payload_with('{"template_id": 2, "topic": "x", "motion_text": "y"}')

      expect(payload.declines_second_reading).to be_nil
    end

    it "keeps a false sufficient_context false, so the orchestrator can widen the context" do
      payload = payload_with('{"template_id": 6, "topic": "x", "motion_text": "y", "sufficient_context": false}')

      expect(payload.sufficient_context).to be(false)
    end

    it "defaults sufficient_context to true when the model omitted it" do
      payload = payload_with('{"template_id": 6, "topic": "x", "motion_text": "y"}')

      expect(payload.sufficient_context).to be(true)
    end

    it "accepts the string booleans models sometimes return" do
      payload = payload_with('{"template_id": 2, "topic": "x", "motion_text": "y", ' \
                             '"declines_second_reading": "false", "sufficient_context": "no"}')

      expect(payload.declines_second_reading).to be(false)
      expect(payload.sufficient_context).to be(false)
    end

    it "treats an unrecognised value as unanswered rather than as true" do
      payload = payload_with('{"template_id": 2, "topic": "x", "motion_text": "y", "declines_second_reading": "maybe"}')

      expect(payload.declines_second_reading).to be_nil
    end

    it "round-trips a false declines_second_reading through the constructor" do
      payload = described_class.new(template_id: 2, topic: "x", motion_text: "y", declines_second_reading: false)

      expect(payload.declines_second_reading).to be(false)
    end
  end

  describe ".json_schema" do
    it "returns a valid JSON Schema draft-07 specification" do
      schema = described_class.json_schema
      expect(schema[:type]).to eq("object")
      expect(schema[:required]).to include("template_id", "topic", "motion_text", "mover_claims")
      expect(schema[:properties].keys).to include(
        :target_name, :target_electorate, :committee_name,
        :regulation_name, :business_name, :rearrangement_description
      )
    end

    # The catalogue grew to 28 but the schema still capped template_id at 23, so the document
    # the model is handed disagreed with the catalogue in the same prompt.
    it "allows the whole 28-template catalogue" do
      schema = described_class.json_schema

      expect(schema[:properties][:template_id][:maximum]).to eq(28)
    end
  end
end
