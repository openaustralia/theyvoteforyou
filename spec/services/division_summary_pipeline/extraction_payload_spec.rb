# frozen_string_literal: true

require "spec_helper"

describe DivisionSummaryPipeline::ExtractionPayload do
  let(:reply) do
    {
      "interpretation" => { "template_id" => 13, "declines_second_reading" => nil, "missing" => [] },
      "references" => {
        "explanation" => ["S2.4", "s2.5 "],
        "motion" => [],
        "facts" => { "committee_name" => { "unit" => "S2.2", "text" => "Economics References Committee" } }
      }
    }
  end

  describe ".from_json" do
    it "reads the interpretation and the references apart" do
      payload = described_class.from_json(reply.to_json)

      expect(payload.template_id).to eq(13)
      expect(payload.missing).to eq([])
      expect(payload.references.explanation).to eq(%w[S2.4 S2.5])
      expect(payload.references.facts[:committee_name].to_h).to eq(unit: "S2.2", text: "Economics References Committee")
    end

    it "strips markdown code fences and a line of preamble" do
      payload = described_class.from_json("Here is the JSON:\n```json\n#{reply.to_json}\n```")

      expect(payload.template_id).to eq(13)
    end

    it "is nil for a reply that is not JSON, or has no interpretation" do
      expect(described_class.from_json("I could not find the motion.")).to be_nil
      expect(described_class.from_json({ "template_id" => 2 }.to_json)).to be_nil
      expect(described_class.from_json("")).to be_nil
    end

    # The old prompts asked for a title and a description the model wrote itself. That shape is
    # no longer a recognised reply at all, so it can never be saved as a draft again.
    it "does not accept a reply in the old title and description shape" do
      expect(described_class.from_json({ "title" => "Motions", "description" => "A debate about it." }.to_json)).to be_nil
    end

    it "ignores fields a model adds that the pipeline has no use for, including its own prose" do
      extra = reply.deep_dup
      extra["interpretation"]["topic"] = "a subject in the model's words"
      extra["references"]["facts"]["party"] = { "unit" => "S2.2", "text" => "Example Party" }

      payload = described_class.from_json(extra.to_json)

      expect(payload.to_h[:interpretation].keys).to contain_exactly(:template_id, :declines_second_reading, :missing)
      expect(payload.references.facts.keys).to eq([:committee_name])
    end

    it "keeps only missing-evidence kinds from the closed list" do
      reply["interpretation"]["missing"] = ["Operative_Motion", "the mover's reasons"]

      expect(described_class.from_json(reply.to_json).missing).to eq(["operative_motion"])
    end

    it "drops a fact reference without a unit or without words to find" do
      reply["references"]["facts"] = { "committee_name" => { "unit" => "S2.2" }, "business_name" => { "text" => "x" } }

      expect(described_class.from_json(reply.to_json).references.facts).to be_empty
    end

    it "accepts keys in any case" do
      shouted = { "INTERPRETATION" => { "Template_ID" => 22, "MISSING" => [] }, "References" => { "Explanation" => [] } }

      expect(described_class.from_json(shouted.to_json).template_id).to eq(22)
    end
  end

  # KNOWN_ISSUES.md KI-15: false once became true, silently inverting Template 2 summaries.
  describe "boolean fields" do
    it "keeps false as false, true as true and an unanswered flag as nil" do
      [[false, false], [true, true], [nil, nil], ["false", false], ["yes", true], ["maybe", nil]].each do |given, read|
        reply["interpretation"]["declines_second_reading"] = given

        expect(described_class.from_json(reply.to_json).declines_second_reading).to eq(read)
      end
    end
  end

  describe ".json_schema" do
    it "offers every template and every fact a template names, and no field for prose" do
      schema = described_class.json_schema
      interpretation = schema.dig(:properties, :interpretation, :properties)
      references = schema.dig(:properties, :references, :properties)

      expect(interpretation[:template_id]).to include(minimum: 1, maximum: DivisionSummaryPipeline::TemplateCatalogue::IDS.max)
      expect(references[:facts][:properties].keys).to match_array(DivisionSummaryPipeline::TemplateCatalogue::ALL_FACTS.keys)
      expect(schema.to_json).not_to include("topic", "claim", "motion_text")
    end
  end
end
