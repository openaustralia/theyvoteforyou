# frozen_string_literal: true

require "spec_helper"

describe DivisionSummarizer do
  let(:division) { create(:division, motion: "That this House bans the thing") }
  let(:stubbed_client) { Aws::BedrockRuntime::Client.new(stub_responses: true) }
  let(:models) { { "test-model" => "test.model-v1:0" } }
  let(:summarizer) { described_class.new(division, models: models, client: stubbed_client) }

  # The stub validator requires the full response shape even though our code only reads
  # output.message.content - stop_reason/usage/metrics are irrelevant to the tests but mandatory here.
  def stub_converse_text(text)
    stubbed_client.stub_responses(
      :converse,
      output: { message: { role: "assistant", content: [{ text: text }] } },
      stop_reason: "end_turn",
      usage: { input_tokens: 1, output_tokens: 1, total_tokens: 2 },
      metrics: { latency_ms: 1 }
    )
  end

  describe "#summarize_with" do
    it "writes a title and description" do
      stub_converse_text(%({"title": "Motions — Coal Seam Gas", "description": "The Senate voted on a motion about coal seam gas."}))

      result = summarizer.summarize_with("test.model-v1:0")

      expect(result.title).to eq "Motions — Coal Seam Gas"
      expect(result.description).to eq "The Senate voted on a motion about coal seam gas."
      expect(result.error).to be_nil
    end

    it "extracts the JSON even when a model wraps it in a code fence" do
      stub_converse_text(<<~TEXT)
        ```json
        {"title": "Motions — Coal Seam Gas", "description": "Wrapped in a fence."}
        ```
      TEXT

      result = summarizer.summarize_with("test.model-v1:0")

      expect(result.title).to eq "Motions — Coal Seam Gas"
      expect(result.description).to eq "Wrapped in a fence."
    end

    it "records an error, rather than a blank summary, when the response is missing title/description" do
      stub_converse_text(%({"answer": "the model didn't return what we asked for"}))

      result = summarizer.summarize_with("test.model-v1:0")

      expect(result.title).to be_nil
      expect(result.error).to eq "Model response was missing title/description"
    end

    it "records an error when the response is valid JSON but not an object" do
      stub_converse_text(%(["not", "an", "object"]))

      result = summarizer.summarize_with("test.model-v1:0")

      expect(result.title).to be_nil
      expect(result.error).to eq "Model response was missing title/description"
    end

    it "records an error when the response isn't valid JSON" do
      stub_converse_text("sorry, I can't help with that")

      result = summarizer.summarize_with("test.model-v1:0")

      expect(result.error).to include("Could not parse response")
    end

    it "records an error when Bedrock itself fails, rather than raising" do
      stubbed_client.stub_responses(:converse, "ServiceUnavailableException")

      result = summarizer.summarize_with("test.model-v1:0")

      expect(result.model).to eq "test.model-v1:0"
      expect(result.error).to be_present
    end
  end

  describe "#summarize_with_all_models" do
    it "asks every configured model and keys the results by label" do
      models = { "model-a" => "a.model-v1:0", "model-b" => "b.model-v1:0" }
      summarizer = described_class.new(division, models: models, client: stubbed_client)
      stub_converse_text(%({"title": "A title", "description": "A description."}))

      results = summarizer.summarize_with_all_models

      expect(results.keys).to contain_exactly("model-a", "model-b")
      expect(results.values).to all(have_attributes(title: "A title"))
    end
  end
end
