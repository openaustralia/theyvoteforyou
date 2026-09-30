# frozen_string_literal: true

require "aws-sdk-bedrockruntime"

# Orchestrates the 5-stage AI division summary pipeline:
# 1. Gather the facts and the Hansard, and find the motion, mover and question by rule (ContextBuilder)
# 2. Classify the vote against fixed procedural rules (ProceduralRouter)
# 3. Ask a model which template fits and where the evidence is (SemanticExtractor)
# 4. Turn the model's references into Hansard's own words, refusing what does not resolve (ProvenanceValidator)
# 5. Compile the verified evidence into Markdown from a human-written template (TemplateCompiler)
#
# The design turns on one constraint: the model selects, it never writes. It answers with a
# template number, a yes or no, and IDs pointing into the transcript; every published word is
# template prose, a database fact or Hansard's own text retrieved by code. ARCHITECTURE.md in
# app/services/division_summary_pipeline/ explains why each stage exists and what is not wired
# up yet.
#
# Read-only: nothing here writes to the database. Every Result is a draft for human review,
# saved as an AiDivisionSummary and edited onto the Division through the WikiMotion form, with a
# "Reviewer Only" report at its foot recording how it was made.
class DivisionSummarizer
  # Which AI models to ask. Borrowed from the policy classifier so the two AI features share one
  # model list and one set of credentials; choosing a model deliberately for this feature is open
  # work (ARCHITECTURE.md section 13).
  MODELS = DivisionPolicyClassifier::MODELS.dup.freeze

  # `raw` holds the model's untouched reply so a reviewer can judge what it actually said, not
  # only what the pipeline made of it. Failures arrive here as `error` rather than as exceptions,
  # so one bad model or division doesn't abandon the rest of a run.
  Result = Struct.new(:model, :title, :description, :raw, :error, keyword_init: true)

  # client: only for tests, to inject a stubbed Aws::BedrockRuntime::Client
  # xml_content: optional raw or debates XML string for offline tests/fixtures
  # xml_fetcher: optional callable (house, date) -> parsed XML for earlier sitting days, for
  #   offline tests; see ContextBuilder.build
  # extractor: optional custom/mock extractor instance
  def initialize(division, models: MODELS, client: nil, xml_content: nil, xml_fetcher: nil, extractor: nil)
    @division = division
    @models = models
    @client = client
    @xml_content = xml_content
    @xml_fetcher = xml_fetcher
    @extractor = extractor
  end

  # Several models are asked the same division so a reviewer can compare drafts before any one
  # model is trusted; which models to keep asking is still an open decision.
  def summarize_with_all_models
    @models.transform_values { |model_id| summarize_with(model_id) }
  end

  def summarize_with(model_id)
    packet = hansard_packet
    extractor = @extractor || DivisionSummaryPipeline::SemanticExtractor.new(model_id, client: client)
    raw_response = extractor.extract_raw(packet)

    # Unparseable output is not retried: a model that ignored the schema once is more useful to
    # a reviewer as a saved raw response than as a second guess.
    extraction = DivisionSummaryPipeline::ExtractionPayload.from_json(raw_response)
    unless extraction
      return failure(model_id, packet, raw_response,
                     "Could not parse response: model returned invalid JSON or empty response")
    end

    # Debate is routinely adjourned and resumed, and deferred divisions are put days after the
    # motion was moved, so the speeches beside a vote can lack what the model needs. A model
    # that reports the gap rather than guessing gets one more try over the whole sitting day and
    # the earlier days of the same debate.
    widening_failure = nil
    if wider_packet_wanted?(extraction, packet)
      widened, widened_response, widened_extraction, widening_failure = widened_attempt(extractor, packet)
      if widened_extraction
        packet = widened
        raw_response = widened_response
        extraction = widened_extraction
        # If one model needed the wider packet, the others do too.
        @hansard_packet = widened
      end
    end

    # A single unresolvable motion or required fact fails the whole draft rather than being left
    # blank, because a summary that is right except for one missing name is still wrong.
    validation = DivisionSummaryPipeline::ProvenanceValidator.validate(extraction, packet)
    return invalid(model_id, packet, raw_response, extraction, validation, widening_failure:) unless validation.valid?

    # Stage 5. PLACEHOLDER, not dead code: digest_section is deliberately nil until a Bills Digest
    # lookup exists, so every compiled summary currently gets the "No Bill Digest found."
    # fallback. See "Hooking it up to live systems" in division_summary_pipeline/ARCHITECTURE.md
    # for the contract a future digest integration must meet.
    compiler = DivisionSummaryPipeline::TemplateCompiler.new
    markdown = compiler.compile(packet.facts, extraction.interpretation, validation.evidence, digest_section: nil)
    title = DivisionSummaryPipeline::DraftTitle.for(heading: packet.heading, template_id: extraction.template_id,
                                                    fallback: packet.facts.name, bill_titles: packet.facts.bill_titles)
    report = DivisionSummaryPipeline::ReviewerReport.render(model_id: model_id, packet: packet, title: title,
                                                            extraction: extraction, validation: validation,
                                                            fallbacks: compiler.fallbacks,
                                                            widening_failure: widening_failure)
    Result.new(model: model_id, title: title, description: "#{markdown}\n\n#{report}", raw: raw_response, error: nil)
  rescue Aws::Errors::ServiceError => e
    Result.new(model: model_id, error: e.message)
  rescue StandardError => e
    Result.new(model: model_id, error: "Pipeline error: #{e.message}")
  end

  private

  attr_reader :division

  # Lazy so nothing contacts AWS at boot: a machine with no Bedrock credentials still starts the
  # app and still runs the whole offline suite.
  def client
    @client ||= DivisionSummaryPipeline::SemanticExtractor.bedrock_client
  end

  # The Hansard context packet for this division, built once and shared by every model: it
  # depends only on the division, so building it per model would re-fetch and re-parse the same
  # day's XML for each. When the question only refers to a motion and Stage 1 could not find
  # the motion beside it, the wider packet is built straight away rather than after a model has
  # said so: the code can already tell the evidence is missing.
  def hansard_packet
    @hansard_packet ||= begin
      packet = build_packet(:subdebate)
      packet.question_by_reference? && !packet.motion_found? ? widened_packet(packet) : packet
    end
  end

  # Routing is about this division and was decided on the speeches beside it. Routed again, the
  # widened packet would be read from the start of the day's transcript, which is some other
  # debate, and could fence this and every later model differently.
  def widened_packet(packet)
    build_packet(:sitting_day, routing: packet.routing)
  end

  # A question that is the whole motion has no terms to find, so the model reporting them missing
  # is not a reason to read the whole sitting day (ContextPacket#question_states_motion?). Nor is
  # the evidence a template settled by the question exists for: then the route is in doubt, which
  # the validator tells the reviewer (TemplateCatalogue::DEFINING_EVIDENCE).
  #
  # Nor is a mover's speech when nobody moved anything: the chair put the question itself, the
  # circulated amendments, or under a limitation of debate the remaining questions (Senate Guide
  # No. 17). Two models reported one missing for such a question, and the retry read 78,535 tokens
  # to come back with the same answer (KI-32). And terms Stage 1 found by
  # rule win over the model's, so its reporting them missing cannot be helped by reading more.
  def wider_packet_wanted?(extraction, packet)
    return false if packet.context_level == :sitting_day

    missing = extraction.missing
    missing -= ["operative_motion"] if packet.question_states_motion? || packet.motion_found?
    missing -= ["mover_speech"] if nobody_moved?(packet)
    routing = packet.routing
    missing -= [DivisionSummaryPipeline::TemplateCatalogue.defining_evidence(routing.template_id)] if routing&.deterministic?
    missing.any?
  end

  def nobody_moved?(packet)
    packet.question_states_motion? || packet.circulation.present? ||
      (packet.limitation_statement.present? && packet.mover.nil?)
  end

  # The retry over the whole sitting day, as [packet, reply, extraction, failure]. The first
  # reply was already a complete answer, so a retry that errors or cannot be read costs only
  # itself: the draft is built from the first reply and `failure` tells the reviewer why. The
  # retry reads far more than the first call and is the one likelier to time out, so letting it
  # fail the whole draft threw away answers that would have compiled.
  def widened_attempt(extractor, packet)
    widened = widened_packet(packet)
    response = extractor.extract_raw(widened)
    extraction = DivisionSummaryPipeline::ExtractionPayload.from_json(response)
    return [widened, response, extraction, nil] if extraction

    [widened, response, nil, "the model's reply to it could not be read"]
  rescue StandardError => e
    [nil, nil, nil, e.message]
  end

  def build_packet(level, routing: nil)
    DivisionSummaryPipeline::ContextBuilder.build(division, xml_content: @xml_content, xml_fetcher: @xml_fetcher,
                                                            context_level: level, routing: routing)
  end

  def failure(model_id, packet, raw_response, error)
    title = DivisionSummaryPipeline::DraftTitle.for(heading: packet.heading, fallback: packet.facts.name,
                                                    bill_titles: packet.facts.bill_titles)
    report = DivisionSummaryPipeline::ReviewerReport.render(model_id: model_id, packet: packet, title: title)
    Result.new(model: model_id, title: title, description: report, raw: raw_response, error: error)
  end

  # A failed draft still carries the Reviewer Only report, so a reviewer can see where the
  # extraction went wrong without rerunning anything.
  def invalid(model_id, packet, raw_response, extraction, validation, widening_failure:)
    title = DivisionSummaryPipeline::DraftTitle.for(heading: packet.heading, template_id: extraction.template_id,
                                                    fallback: packet.facts.name, bill_titles: packet.facts.bill_titles)
    report = DivisionSummaryPipeline::ReviewerReport.render(model_id: model_id, packet: packet, title: title,
                                                            extraction: extraction, validation: validation,
                                                            widening_failure: widening_failure)
    Result.new(model: model_id, title: title, description: report, raw: raw_response,
               error: "Validation failed: #{validation.errors.join('; ')}")
  end
end
