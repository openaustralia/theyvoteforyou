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
    context "when the model answers with structured extraction JSON" do
      before do
        stub_converse_text(
          <<~JSON
            {
              "template_id": 22,
              "topic": "Closure of Debate",
              "motion_text": "That the question be now put."
            }
          JSON
        )
      end

      it "compiles through the template compiler into markdown" do
        expect(result.title).to eq("Closure of Debate")
        expect(result.description).to start_with("**Jargon Explainer:**")
        expect(result.description).to include("> That the question be now put.")
        expect(result.error).to be_nil
      end
    end

    context "when the model answers with legacy title and description" do
      before do
        stub_converse_text(
          %({"title": "Motions - Coal Seam Gas", "description": "The Senate voted on a motion about coal seam gas."})
        )
      end

      it "reads the title" do
        expect(result.title).to eq "Motions - Coal Seam Gas"
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
          {"title": "Motions - Coal Seam Gas", "description": "Wrapped in a fence."}
          ```
        TEXT
      end

      it "reads the title" do
        expect(result.title).to eq "Motions - Coal Seam Gas"
      end

      it "reads the description" do
        expect(result.description).to eq "Wrapped in a fence."
      end
    end

    context "when provenance validation fails on unsupported claims" do
      before do
        stub_converse_text(
          <<~JSON
            {
              "template_id": 2,
              "topic": "Mining Reform",
              "motion_text": "That this House bans the thing",
              "declines_second_reading": false,
              "mover_claims": [
                {
                  "claim": "A completely fabricated claim",
                  "evidence": "a non-existent quote that is not in the motion text",
                  "speaker": "John Doe"
                }
              ]
            }
          JSON
        )
      end

      it "records a validation error and leaves description nil" do
        expect(result.error).to include("Validation failed")
        expect(result.description).to be_nil
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

    # ARCHITECTURE.md constraint 4: the extractor reporting a thin excerpt earns a second
    # attempt over the whole sitting day. That path was unreachable until ExtractionPayload
    # stopped coercing sufficient_context to true (KNOWN_ISSUES.md, KI-15), so it is worth a
    # regression test of its own rather than trusting the constraint.
    # Real Hansard XML rather than a stubbed packet, so Stage 1 finds the mover and routes the
    # question as it would for a live division.
    context "with the division's Hansard XML" do
      let(:division) { create(:division, house: "representatives", date: Date.new(2026, 8, 19), number: 1) }
      # The day opens with another bill's consideration in detail, so the start of the whole
      # day's transcript says something the debate about this division does not.
      let(:xml_content) do
        <<~XML
          <debates>
            <major-heading id="h1" url="x">BILLS</major-heading>
            <minor-heading id="h2" url="x">Other Bill 2026; Consideration in Detail</minor-heading>
            <speech id="s0" speakername="Jess Harlow" time="09:30:00" url="x"><p>We are in consideration in detail of the other bill.</p></speech>
            <minor-heading id="h3" url="x">Example Bill 2026</minor-heading>
            <speech id="s1" speakername="Robin Carrow" time="10:00:00" url="x"><p>I move:</p><p class="italic">That the words "the Minister" be omitted.</p></speech>
            <speech id="s2" speakername="Casey Whitlow" time="10:05:00" url="x"><p>The question is that the amendment be agreed to.</p></speech>
            <division divdate="2026-08-19" divnumber="1" id="d1" time="10:06:00" url="x"><divisioncount ayes="40" noes="30" pairs="0" tellerayes="0" tellernoes="0"/></division>
          </debates>
        XML
      end

      it "names the mover Stage 1 found from Hansard, not whoever the model credits" do
        stub_converse_text(%({"template_id": 4, "topic": "Omitting the Minister", "motion_text": "That the words \\"the Minister\\" be omitted."}))
        summarizer = described_class.new(division, models: models, client: stubbed_client, xml_content: xml_content)

        expect(summarizer.summarize_with(model_id).description).to include("introduced by Representative Robin Carrow")
      end

      context "when the first model reports the excerpt was not enough" do
        let(:models) { { "first" => "first.model-v1:0", "second" => "second.model-v1:0" } }
        let(:packets) { [] }
        let(:extractor) do
          seen = packets
          replies = [
            %({"template_id": 4, "topic": "x", "motion_text": "x", "sufficient_context": false, ) +
              %("missing_context_clue": "the first model's own note"}),
            %({"template_id": 4, "topic": "x", "motion_text": "x"}),
            %({"template_id": 4, "topic": "x", "motion_text": "x"})
          ]
          double = Object.new
          double.define_singleton_method(:extract_raw) do |packet|
            seen << packet
            replies.shift
          end
          double
        end

        before do
          described_class.new(division, models: models, client: stubbed_client, xml_content: xml_content,
                                        extractor: extractor).summarize_with_all_models
        end

        it "keeps the routing decided on the speeches beside the division" do
          expect(packets.map { |packet| packet.procedural_decision.candidate_templates }).to all(eq([2, 4]))
        end

        it "gives the later models the whole day, but not the first model's note" do
          expect(packets.map(&:context_level)).to eq(%i[subdebate sitting_day sitting_day])
          expect(packets[1].extra_context).to eq("the first model's own note")
          expect(packets[2].extra_context).to be_nil
        end
      end
    end

    context "when the model reports the excerpt was not enough" do
      let(:responses) do
        [
          %({"template_id": 22, "topic": "Closure", "motion_text": "That the question be now put.", ) +
            %("sufficient_context": false, "missing_context_clue": "mover's speech is earlier in the day"}),
          %({"template_id": 22, "topic": "Closure of Debate", "motion_text": "That the question be now put.", ) +
            %("sufficient_context": true})
        ]
      end

      let(:extractor) do
        calls = []
        replies = responses.dup
        double = Object.new
        double.define_singleton_method(:calls) { calls }
        double.define_singleton_method(:extract_raw) do |packet|
          calls << packet.context_level
          replies.shift
        end
        double
      end

      let(:summarizer) do
        described_class.new(division, models: models, client: stubbed_client, extractor: extractor)
      end

      it "rebuilds the packet over the whole sitting day and asks again" do
        expect(result.error).to be_nil
        expect(extractor.calls).to eq(%i[subdebate sitting_day])
        expect(result.title).to eq("Closure of Debate")
      end
    end

    context "when the model reports the excerpt was enough" do
      let(:extractor) do
        calls = []
        double = Object.new
        double.define_singleton_method(:calls) { calls }
        double.define_singleton_method(:extract_raw) do |packet|
          calls << packet.context_level
          %({"template_id": 22, "topic": "Closure", "motion_text": "That the question be now put."})
        end
        double
      end

      let(:summarizer) do
        described_class.new(division, models: models, client: stubbed_client, extractor: extractor)
      end

      it "does not widen the context" do
        expect(result.error).to be_nil
        expect(extractor.calls).to eq([:subdebate])
      end
    end
  end
end
