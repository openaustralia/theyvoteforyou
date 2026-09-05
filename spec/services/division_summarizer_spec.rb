# frozen_string_literal: true

require "spec_helper"

describe DivisionSummarizer do
  subject(:result) { summarizer.summarize_with(model_id) }

  let(:model_id) { "test.model-v1:0" }
  let(:models) { { "test-model" => model_id } }
  let(:division) { create(:division, motion: "That this House bans the thing") }
  let(:stubbed_client) { Aws::BedrockRuntime::Client.new(stub_responses: true) }
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
    context "when the model answers as asked" do
      before do
        stub_converse_text(
          %({"title": "Motions — Coal Seam Gas", "description": "The Senate voted on a motion about coal seam gas."})
        )
      end

      it "reads the title" do
        expect(result.title).to eq "Motions — Coal Seam Gas"
      end

      it "reads the description" do
        expect(result.description).to eq "The Senate voted on a motion about coal seam gas."
      end

      it "records no error" do
        expect(result.error).to be_nil
      end
    end

    context "when the model wraps the JSON in a code fence" do
      before do
        stub_converse_text(<<~TEXT)
          ```json
          {"title": "Motions — Coal Seam Gas", "description": "Wrapped in a fence."}
          ```
        TEXT
      end

      it "reads the title" do
        expect(result.title).to eq "Motions — Coal Seam Gas"
      end

      it "reads the description" do
        expect(result.description).to eq "Wrapped in a fence."
      end
    end

    context "when the response has no title or description" do
      before { stub_converse_text(%({"answer": "the model didn't return what we asked for"})) }

      it "records an error" do
        expect(result.error).to eq "Model response was missing title/description"
      end

      it "leaves the title blank" do
        expect(result.title).to be_nil
      end
    end

    context "when the response is JSON but not an object" do
      before { stub_converse_text(%(["not", "an", "object"])) }

      it "records an error" do
        expect(result.error).to eq "Model response was missing title/description"
      end

      it "leaves the title blank" do
        expect(result.title).to be_nil
      end
    end

    context "when the response isn't JSON at all" do
      before { stub_converse_text("sorry, I can't help with that") }

      it "records a parse error" do
        expect(result.error).to include("Could not parse response")
      end
    end

    context "when Bedrock itself fails" do
      before { stubbed_client.stub_responses(:converse, "ServiceUnavailableException") }

      it "records the error rather than raising" do
        expect(result.error).to be_present
      end

      it "still names the model" do
        expect(result.model).to eq model_id
      end
    end
  end

  describe "#summarize_with_all_models" do
    subject(:results) { summarizer.summarize_with_all_models }

    let(:models) { { "model-a" => "a.model-v1:0", "model-b" => "b.model-v1:0" } }

    before { stub_converse_text(%({"title": "A title", "description": "A description."})) }

    it "asks every configured model" do
      expect(results.keys).to contain_exactly("model-a", "model-b")
    end

    it "returns each model's summary" do
      expect(results.values).to all(have_attributes(title: "A title"))
    end
  end
end
