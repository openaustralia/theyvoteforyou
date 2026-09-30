# frozen_string_literal: true

require "spec_helper"

describe DivisionSummarizer do
  let(:model_id) { "test.model-v1:0" }
  let(:models) { { "test-model" => model_id } }
  let(:stubbed_client) { Aws::BedrockRuntime::Client.new(stub_responses: true) }
  let(:division) { create(:division, house: "representatives", date: Date.new(2026, 8, 19), number: 1) }
  # The day opens with another bill's consideration in detail, so the start of the whole day's
  # transcript says something the debate about this division does not. Fictional members.
  let(:xml_content) do
    <<~XML
      <debates>
        <major-heading id="h1" url="x">BILLS</major-heading>
        <minor-heading id="h2" url="x">Other Bill 2026; Consideration in Detail</minor-heading>
        <speech id="s0" speakername="Jess Harlow" time="09:30:00" url="x"><p>We are in consideration in detail of the other bill.</p></speech>
        <minor-heading id="h3" url="x">Example Bill 2026</minor-heading>
        <speech id="s1" speakername="Robin Carrow" time="10:00:00" url="x"><p>This change protects small business.</p><p>I move:</p><p class="italic">That the words "the Minister" be omitted.</p></speech>
        <speech id="s2" speakername="Casey Whitlow" time="10:05:00" url="x"><p>The question is that the amendment be agreed to.</p></speech>
        <division divdate="2026-08-19" divnumber="1" id="d1" time="10:06:00" url="x"><divisioncount ayes="40" noes="30" pairs="0" tellerayes="0" tellernoes="0"/></division>
      </debates>
    XML
  end
  let(:summarizer) { described_class.new(division, models: models, client: stubbed_client, xml_content: xml_content) }

  def reply(template_id: 4, explanation: ["S1.1"], missing: [], motion: [])
    { interpretation: { template_id: template_id, missing: missing },
      references: { explanation: explanation, motion: motion } }.to_json
  end

  # The stub validator requires the full response shape even though our code only reads
  # output.message.content: stop_reason/usage/metrics are irrelevant here but mandatory.
  def stub_converse_text(text)
    stubbed_client.stub_responses(
      :converse,
      output: { message: { role: "assistant", content: [{ text: text }] } },
      stop_reason: "end_turn", usage: { input_tokens: 1, output_tokens: 1, total_tokens: 2 }, metrics: { latency_ms: 1 }
    )
  end

  # Records each packet it is asked about and answers from a list. An answer that is a lambda is
  # called instead, so an example can make a later call fail.
  def scripted_extractor(replies, seen = [])
    extractor = Object.new
    extractor.define_singleton_method(:extract_raw) do |packet|
      seen << packet
      answer = replies.shift
      answer.respond_to?(:call) ? answer.call : answer
    end
    extractor
  end

  describe "#summarize_with" do
    subject(:result) { summarizer.summarize_with(model_id) }

    context "when the model answers with references that resolve" do
      before { stub_converse_text(reply) }

      it "compiles a draft quoting only Hansard, titled by rule, with the reviewer's report at its foot" do
        expect(result.error).to be_nil
        expect(result.title).to eq("Bills - Example Bill 2026; Consideration in Detail Amendment")
        expect(result.description).to start_with("**Bill Timeline:**")
        expect(result.description).to include("introduced by Robin Carrow MP",
                                              "At 10:00 AM, Robin Carrow MP said:\n\n> This change protects small business.",
                                              "> That the words \"the Minister\" be omitted.",
                                              "At 10:05 AM, Casey Whitlow MP, in the chair, put the following question:")
        expect(result.description).to include("---\n\n## Reviewer Only")
        expect(result.raw).to eq(reply)
      end
    end

    context "when the model picks a template the router does not allow" do
      before { stub_converse_text(reply(template_id: 6)) }

      it "records a validation error, and still gives the reviewer the report" do
        expect(result.error).to include("Validation failed", "outside the allowed templates [2, 4]")
        expect(result.description).to start_with("---\n\n## Reviewer Only")
        expect(result.description).to include("### Validation errors")
      end
    end

    context "when the response isn't JSON at all" do
      before { stub_converse_text("sorry, I can't help with that") }

      it "records a parse error, keeps the reply, and gives the reviewer the report" do
        expect(result.error).to include("Could not parse response")
        expect(result.raw).to eq("sorry, I can't help with that")
        expect(result.description).to include("| Reply | could not be read |")
      end
    end

    # The old prompts asked for a title and description the model wrote itself; that shape is no
    # longer a reply the pipeline accepts at all.
    context "when the model answers in the old title and description shape" do
      before { stub_converse_text(%({"title": "Motions - Example", "description": "A summary in the model's words."})) }

      it "is not saved as a draft" do
        expect(result.error).to include("Could not parse response")
        expect(result.description).not_to include("A summary in the model's words.")
      end
    end

    context "when Bedrock itself fails" do
      before { stubbed_client.stub_responses(:converse, "ServiceUnavailableException") }

      it "records the error rather than raising, and still names the model" do
        expect(result.error).to be_present
        expect(result.model).to eq model_id
      end
    end

    # The retry reads far more than the first call, so it is the one likelier to time out, and
    # the first reply was already a complete answer.
    context "when the retry over the whole sitting day fails" do
      let(:first_reply) { reply(missing: ["mover_speech"]) }

      def summarize_with_retry(second)
        extractor = scripted_extractor([first_reply, second])
        described_class.new(division, models: models, client: stubbed_client, xml_content: xml_content,
                                      extractor: extractor).summarize_with(model_id)
      end

      it "builds the draft from the first reply, and tells the reviewer why" do
        result = summarize_with_retry(-> { raise "the model timed out" })

        expect(result.error).to be_nil
        expect(result.raw).to eq(first_reply)
        expect(result.description).to include("| Context level | subdebate |",
                                              "| Sitting day retry | failed (the model timed out), so this draft uses the first reply |")
      end

      it "does the same when the retry's reply cannot be read" do
        result = summarize_with_retry("sorry, I can't help with that")

        expect(result.error).to be_nil
        expect(result.description).to include("failed (the model's reply to it could not be read)")
      end
    end

    # Reporting the terms of such a question missing sent the pipeline to read the whole sitting
    # day for terms that do not exist.
    context "when the question is the whole motion and the model reports its terms missing" do
      let(:packets) { [] }
      let(:xml_content) do
        super().sub("The question is that the amendment be agreed to.",
                    "The question now is that the remaining stages of the bill be agreed to, and the bill be now passed.")
               .sub(%r{<p>I move:</p><p class="italic">That the words "the Minister" be omitted.</p>}, "")
      end
      let(:summarizer) do
        extractor = scripted_extractor([reply(template_id: 6, explanation: [], missing: ["operative_motion"])], packets)
        described_class.new(division, models: models, client: stubbed_client, xml_content: xml_content, extractor: extractor)
      end

      it "does not widen the context, and compiles from the question" do
        expect(result.error).to be_nil
        expect(packets.map(&:context_level)).to eq([:subdebate])
        expect(result.description).to include("through all its remaining stages")
      end

      # KI-32: nobody moves the remaining stages, so there is no mover's
      # speech to find, and the retry read 78,535 tokens to say so again.
      it "does not widen for a mover's speech reported missing either" do
        extractor = scripted_extractor([reply(template_id: 6, explanation: [], missing: ["mover_speech"])], packets)
        described_class.new(division, models: models, client: stubbed_client, xml_content: xml_content, extractor: extractor)
                       .summarize_with(model_id)

        expect(packets.map(&:context_level)).to eq([:subdebate])
      end
    end

    context "when no Hansard XML is available" do
      let(:division) { create(:division, motion: "That this House bans the thing") }
      let(:summarizer) { described_class.new(division, models: models, client: stubbed_client) }

      before do
        allow(DataLoader::Debates).to receive(:fetch_xml_document).and_return(nil)
        stub_converse_text(reply(template_id: 15, explanation: [], motion: ["S1.1"]))
      end

      it "quotes the motion the model pointed at in the Division record, crediting nobody with moving it" do
        expect(result.error).to be_nil
        expect(result.description).to include("The following motion was moved:\n\n> That this House bans the thing")
      end
    end
  end

  describe "#summarize_with_all_models" do
    let(:models) { { "first" => "first.model-v1:0", "second" => "second.model-v1:0" } }

    it "asks every configured model" do
      stub_converse_text(reply)

      expect(summarizer.summarize_with_all_models.values).to all(have_attributes(error: nil))
    end

    context "when the first model reports evidence missing" do
      let(:packets) { [] }

      before do
        extractor = scripted_extractor([reply(missing: ["mover_speech"]), reply, reply], packets)
        described_class.new(division, models: models, client: stubbed_client, xml_content: xml_content,
                                      extractor: extractor).summarize_with_all_models
      end

      it "asks again over the whole sitting day, and gives the later models the wider packet too" do
        expect(packets.map(&:context_level)).to eq(%i[subdebate sitting_day sitting_day])
      end

      # Routed again, the wider packet would be read from the start of the day, which is the
      # other bill's consideration in detail (KNOWN_ISSUES.md, KI-27).
      it "keeps the routing decided on the speeches beside the division" do
        expect(packets.map { |packet| packet.routing.allowed_templates }).to all(eq([2, 4]))
      end
    end

    it "does not widen the context when nothing is reported missing" do
      packets = []
      described_class.new(division, models: { "only" => "only.model-v1:0" }, client: stubbed_client,
                                    xml_content: xml_content, extractor: scripted_extractor([reply], packets))
                     .summarize_with_all_models

      expect(packets.map(&:context_level)).to eq([:subdebate])
    end

    # KI-44: the terms of amendments the chair puts are in the chair's own
    # statement, so there is nothing more to look for.
    it "does not widen for amendments the chair put when their terms are in the chair's statement" do
      circulated = xml_content.sub("<p>The question is that the amendment be agreed to.</p>",
                                   "<p>I will now deal with the amendment circulated by the Example Party. The question is that " \
                                   "the amendment on sheet 9001 be agreed to.</p><p class=\"italic\">Omit \"the Minister\", " \
                                   "substitute \"the Secretary\".</p>")
                              .sub(%r{<p>I move:</p><p class="italic">That the words "the Minister" be omitted.</p>}, "")
      packets = []
      result = described_class.new(division, models: { "only" => "only.model-v1:0" }, client: stubbed_client,
                                             xml_content: circulated, extractor: scripted_extractor([reply(explanation: [])], packets))
                              .summarize_with("only.model-v1:0")

      expect(packets.map(&:context_level)).to eq([:subdebate])
      expect(result.description).to include("The following amendment, circulated by the Example Party, was put:\n\n" \
                                            "> Omit \"the Minister\", substitute \"the Secretary\".")
    end

    # KI-59: at Senate 18 August 2026 #4 the route settled on a select committee,
    # both models said there was no committee, and the retry could only find none again.
    it "does not widen when the model cannot find what a settled template is about, and says so" do
      committee = xml_content.sub("<p>The question is that the amendment be agreed to.</p>",
                                  "<p>The question is that a select committee be appointed to inquire into the scheme.</p>")
                             .sub(%r{<p>I move:</p><p class="italic">That the words "the Minister" be omitted.</p>}, "")
      packets = []
      result = described_class.new(division, models: { "only" => "only.model-v1:0" }, client: stubbed_client, xml_content: committee,
                                             extractor: scripted_extractor([reply(template_id: 12, explanation: [],
                                                                                  missing: ["committee"])], packets))
                              .summarize_with("only.model-v1:0")

      expect(packets.map(&:context_level)).to eq([:subdebate])
      expect(result.description).to include("The model could not find the committee a matter is referred to, which Template 12 " \
                                            "is about, though the question settled that template: check the route (SELECT_COMMITTEE).")
    end

    # Structural before semantic: when the question only refers to a motion and Stage 1 cannot
    # find it beside the division, the code already knows the evidence is missing.
    it "starts from the whole sitting day when the question refers to a motion Stage 1 cannot find" do
      referring = xml_content.sub("The question is that the amendment be agreed to.",
                                  "The question is that the amendment moved by the member for Exampleton be agreed to.")
                             .sub(%r{<p>I move:</p><p class="italic">That the words "the Minister" be omitted.</p>}, "")
      packets = []
      described_class.new(division, models: { "only" => "only.model-v1:0" }, client: stubbed_client,
                                    xml_content: referring, extractor: scripted_extractor([reply(explanation: [])], packets))
                     .summarize_with_all_models

      expect(packets.map(&:context_level)).to eq([:sitting_day])
    end
  end
end
