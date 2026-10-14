# frozen_string_literal: true

require "spec_helper"

describe DivisionSummaryPipeline::SemanticExtractor do
  let(:chair) do
    summary_speech("<p>The question is that the question be now put.</p>", id: "s2", name: "Robin Castellan",
                                                                           gid: "uk.org.publicwhip/member/2", time: "10:14")
  end
  let(:mover) do
    summary_speech("<p>I move: That the question be now put.</p>", id: "s1", name: "Jordan McAllister",
                                                                   gid: "uk.org.publicwhip/member/1", time: "10:13")
  end
  let(:packet) do
    summary_packet(speeches: [mover, chair], question: "The question is that the question be now put.",
                   routing: DivisionSummaryPipeline::RoutingDecision.settled(22, rule_name: "CLOSURE_OF_DEBATE", reason: "test"),
                   facts: { house: "representatives", date: "2026-08-19", number: 1, clock_time: "10:15 AM" })
  end
  let(:reply) { { interpretation: { template_id: 22, missing: [] }, references: { explanation: [] } }.to_json }

  describe "#extract_raw" do
    it "sends the system prompt and this packet's user prompt through the injected caller, and returns the reply untouched" do
      prompts = []
      raw = described_class.new(llm_caller: ->(system, user) { (prompts << [system, user]) && reply }).extract_raw(packet)

      expect(raw).to eq(reply)
      expect(prompts.first[0]).to eq(DivisionSummaryPipeline::ExtractionPrompt.system_prompt)
      expect(prompts.first[1]).to eq(DivisionSummaryPipeline::ExtractionPrompt.user_prompt(packet))
    end

    it "asks Bedrock at temperature 0 when no caller is injected" do
      client = Aws::BedrockRuntime::Client.new(stub_responses: true, region: "ap-southeast-2")
      client.stub_responses(:converse, { output: { message: { role: "assistant", content: [{ text: reply }] } },
                                         stop_reason: "end_turn", usage: { input_tokens: 1, output_tokens: 1, total_tokens: 2 },
                                         metrics: { latency_ms: 1 } })

      expect(described_class.new("example-model", client: client).extract_raw(packet)).to eq(reply)
      expect(client.api_requests.first[:params]).to include(model_id: "example-model", inference_config: { temperature: 0 })
    end
  end

  describe "#extract" do
    it "parses the reply into an ExtractionPayload" do
      extraction = described_class.new(llm_caller: ->(_system, _user) { reply }).extract(packet)

      expect(extraction.template_id).to eq(22)
    end
  end
end
