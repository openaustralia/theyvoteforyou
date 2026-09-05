# frozen_string_literal: true

require "spec_helper"

describe DivisionPolicyClassifier do
  let(:division) { create(:division, motion: "That this House bans the thing") }
  let(:stubbed_client) { Aws::BedrockRuntime::Client.new(stub_responses: true) }
  let(:models) { { "test-model" => "test.model-v1:0" } }
  let(:classifier) { described_class.new(division, models: models, client: stubbed_client) }

  # The stub validator requires the full response shape even though our code only reads
  # output.message.content - stop_reason/usage/metrics are irrelevant to the tests but mandatory here.
  def converse_response(text)
    {
      output: { message: { role: "assistant", content: [{ text: text }] } },
      stop_reason: "end_turn",
      usage: { input_tokens: 1, output_tokens: 1, total_tokens: 2 },
      metrics: { latency_ms: 1 }
    }
  end

  def stub_converse_text(text)
    stubbed_client.stub_responses(:converse, converse_response(text))
  end

  describe "#classify_with" do
    it "matches an existing policy" do
      policy = create(:policy)
      stub_converse_text(%({"match": "existing", "policy_id": #{policy.id}, "direction": "for", "reasoning": "because"}))

      result = classifier.classify_with("test.model-v1:0")

      expect(result.match).to eq "existing"
      expect(result.policy).to eq policy
      expect(result.direction).to eq "for"
      expect(result.reasoning).to eq "because"
      expect(result.error).to be_nil
      expect(result.summary).to eq "For policy #{policy.id}"
    end

    it "proposes a new policy when none fit" do
      stub_converse_text(<<~JSON)
        {"match": "new", "new_policy_name": "banning things", "new_policy_description": "the government should ban things", "direction": "against", "reasoning": "no existing policy covers this"}
      JSON

      result = classifier.classify_with("test.model-v1:0")

      expect(result.match).to eq "new"
      expect(result.new_policy_name).to eq "banning things"
      expect(result.new_policy_description).to eq "the government should ban things"
      expect(result.direction).to eq "against"
      expect(result.summary).to eq "Against new policy I propose"
    end

    it "extracts the JSON even when a model wraps it in a code fence" do
      policy = create(:policy)
      stub_converse_text(<<~TEXT)
        ```json
        {"match": "existing", "policy_id": #{policy.id}, "direction": "against", "reasoning": "wrapped in a fence"}
        ```
      TEXT

      result = classifier.classify_with("test.model-v1:0")

      expect(result.match).to eq "existing"
      expect(result.policy).to eq policy
    end

    it "records an error, rather than a misleading summary, when the response is missing match/direction" do
      stub_converse_text(%({"reasoning": "the model didn't return what we asked for"}))

      result = classifier.classify_with("test.model-v1:0")

      expect(result.error).to be_nil
      expect(result.summary).to eq "Error: model response was missing match/direction"
    end

    it "records an error when the response isn't valid JSON" do
      stub_converse_text("sorry, I can't help with that")

      result = classifier.classify_with("test.model-v1:0")

      expect(result.error).to include("Could not parse response")
      expect(result.summary).to eq "Error: #{result.error}"
    end

    it "records an error when Bedrock itself fails, rather than raising" do
      stubbed_client.stub_responses(:converse, "ServiceUnavailableException")

      result = classifier.classify_with("test.model-v1:0")

      expect(result.model).to eq "test.model-v1:0"
      expect(result.error).to be_present
    end

    it "only includes published policies in the prompt, not provisional ones" do
      published = create(:policy, name: "a published policy")
      provisional = create(:provisional_policy, name: "a provisional policy")

      prompt = classifier.send(:system_prompt)

      expect(prompt).to include(published.name)
      expect(prompt).not_to include(provisional.name)
    end
  end

  describe "#classify_with_all_models" do
    it "asks every configured model and keys the results by label" do
      models = { "model-a" => "a.model-v1:0", "model-b" => "b.model-v1:0" }
      classifier = described_class.new(division, models: models, client: stubbed_client)
      stub_converse_text(%({"match": "new", "direction": "for", "reasoning": "x"}))

      results = classifier.classify_with_all_models

      expect(results.keys).to contain_exactly("model-a", "model-b")
      expect(results.values).to all(have_attributes(match: "new"))
    end
  end
end
