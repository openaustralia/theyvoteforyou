# frozen_string_literal: true

require "spec_helper"

describe DivisionSummaryPipeline::SemanticExtractor do
  let(:packet) do
    DivisionSummaryPipeline::ContextPacket.new(
      division_id: 1052,
      date: "2026-08-19",
      house: "representatives",
      clock_time: "10:15 AM",
      speaker_question: "The question is that the question be now put.",
      hansard_context: "DEBATE: Bills\n\nSPEECH: Jordan McAllister [10:14]:\nThat the question be now put.",
      debate_heading: "Bills",
      division_metadata: { name: "Closure of Debate", aye_votes: 82, no_votes: 54 },
      context_level: :subdebate
    )
  end

  describe "#extract_raw" do
    it "sends the system prompt and the built user prompt through the injected caller" do
      prompts = []
      llm_caller = lambda do |system_prompt, user_prompt|
        prompts << [system_prompt, user_prompt]
        "{\"template_id\": 22, \"topic\": \"Closure of Debate\", \"motion_text\": \"That the question be now put.\"}"
      end

      raw = described_class.new(llm_caller: llm_caller).extract_raw(packet)

      expect(raw).to include("template_id")
      expect(prompts.length).to eq(1)
      expect(prompts.first[0]).to include("NEUTRALITY IS NOT OPTIONAL")
      expect(prompts.first[1]).to include("<speaker_question>")
      expect(prompts.first[1]).to include("That the question be now put.")
      expect(prompts.first[1]).to include("<hansard_context>")
    end
  end

  describe "#extract" do
    it "parses the model's raw JSON into an ExtractionPayload" do
      llm_caller = ->(_system_prompt, _user_prompt) { "{\"template_id\": 22, \"topic\": \"Closure\", \"motion_text\": \"x\"}" }

      extraction = described_class.new(llm_caller: llm_caller).extract(packet)

      expect(extraction).to be_a(DivisionSummaryPipeline::ExtractionPayload)
      expect(extraction.template_id).to eq(22)
    end
  end

  describe "#system_prompt" do
    it "carries the template catalogue, the neutrality rule and the Australian English constraint" do
      prompt = described_class.new.system_prompt

      expect(prompt).to include("23: Member Be No Longer Heard")
      expect(prompt).to include("NEUTRALITY IS NOT OPTIONAL")
      expect(prompt).to include("Australian English")
    end

    it "scopes claims to what each procedural template actually decides" do
      prompt = described_class.new.system_prompt

      expect(prompt).to include("They are never about the subject matter the documents deal with.")
      expect(prompt).to include("not about the merits of that underlying matter.")
      expect(prompt).to include("so make no claims about the underlying question.")
    end

    it "warns about resumed debates and headings that do not describe the vote" do
      prompt = described_class.new.system_prompt

      expect(prompt).to include("CONTEXT SUFFICIENCY AND RESUMED DEBATES")
      expect(prompt).to include("Do not reconstruct a missing speech from")
      expect(prompt).to include("DEBATE HEADINGS ARE NOT VOTES")
    end
  end
end
