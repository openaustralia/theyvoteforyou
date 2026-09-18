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

    it "returns nil for invalid JSON" do
      expect(described_class.from_json("invalid json")).to be_nil
    end
  end

  describe ".json_schema" do
    it "returns a valid JSON Schema draft-07 specification" do
      schema = described_class.json_schema
      expect(schema[:type]).to eq("object")
      expect(schema[:required]).to include("template_id", "topic", "motion_text", "mover_claims")
    end
  end
end

