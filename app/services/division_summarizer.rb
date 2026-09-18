# frozen_string_literal: true

require "aws-sdk-bedrockruntime"

# DivisionSummarizer acts as an orchestrator executing the 5-stage AI division summary
# pipeline:
# 1. Fetch wider Hansard context (ContextBuilder)
# 2. Run the Procedural State Machine (ProceduralRouter)
# 3. Run Semantic Extraction for structured JSON (SemanticExtractor)
# 4. Assert mechanical zero-hallucination provenance (ProvenanceValidator)
# 5. Compile verified data into publication-ready Markdown (TemplateCompiler)
#
# It is read-only: nothing here writes to the database. Every result is a draft for human
# review via the existing WikiMotion edit form or saved to AiDivisionSummary.
class DivisionSummarizer
  MODELS = DivisionPolicyClassifier::MODELS.dup.freeze
  REGION = DivisionPolicyClassifier::REGION

  Result = Struct.new(:model, :title, :description, :raw, :error, keyword_init: true)

  # client: only for tests, to inject a stubbed Aws::BedrockRuntime::Client
  # xml_content: optional raw or debates XML string for offline tests/fixtures
  # extractor: optional custom/mock extractor instance
  def initialize(division, models: MODELS, client: nil, xml_content: nil, extractor: nil)
    @division = division
    @models = models
    @client = client
    @xml_content = xml_content
    @extractor = extractor
  end

  def summarize_with_all_models
    @models.transform_values { |model_id| summarize_with(model_id) }
  end

  def summarize_with(model_id)
    # Stage 1: Fetch wider Hansard debate context. Built once per DivisionSummarizer and
    # shared by every model call: the packet depends only on the division (plus any context
    # expansion below), not on the model, so building it per model would re-fetch and
    # re-parse the same day's Hansard XML for every model in #summarize_with_all_models.
    packet = hansard_packet

    # Stage 2: Procedural Router. ContextBuilder already runs the router and attaches its
    # decision to the packet; route defensively only if a packet ever arrives without one.
    packet.procedural_decision ||= DivisionSummaryPipeline::ProceduralRouter.route(
      speaker_question: packet.speaker_question,
      chamber: packet.house,
      debate_heading: packet.debate_heading,
      hansard_snippet: packet.hansard_context.to_s[0..1000]
    )

    # Stage 3: Semantic Extractor (prompting the LLM strictly for structured JSON)
    extractor = @extractor || DivisionSummaryPipeline::SemanticExtractor.new(model_id, client: client)
    raw_response = extractor.extract_raw(packet)

    extraction = DivisionSummaryPipeline::ExtractionPayload.from_json(raw_response)
    unless extraction
      return Result.new(
        model: model_id,
        error: "Could not parse response: model returned invalid JSON or empty response",
        raw: raw_response
      )
    end

    # Handle legacy title/description payload from older prompts
    if extraction.legacy?
      return Result.new(
        model: model_id,
        title: extraction.legacy_title,
        description: extraction.legacy_description,
        raw: raw_response
      )
    end

    # Progressive context expansion fallback if context was reported insufficient
    if !extraction.sufficient_context && packet.context_level != :sitting_day
      expanded_packet = DivisionSummaryPipeline::ContextBuilder.build(
        division,
        xml_content: @xml_content,
        context_level: :sitting_day,
        extra_context: extraction.missing_context_clue
      )
      expanded_response = extractor.extract_raw(expanded_packet)
      expanded_extraction = DivisionSummaryPipeline::ExtractionPayload.from_json(expanded_response)
      if expanded_extraction
        extraction = expanded_extraction
        packet = expanded_packet
        raw_response = expanded_response
        # Keep the widest context for the remaining models: if one model needed the sitting
        # day's debate to extract with evidence, the others do too.
        @hansard_packet = packet
      end
    end

    # Stage 4: Provenance Validator (mechanically asserting evidence quotes in source)
    validation = DivisionSummaryPipeline::ProvenanceValidator.validate(extraction, packet)
    unless validation.is_valid
      error_msg = "Validation failed: #{validation.errors.join('; ')}"
      return Result.new(
        model: model_id,
        title: extraction.topic.presence || division_default_title,
        description: nil,
        raw: raw_response,
        error: error_msg
      )
    end

    # Stage 5: Template Compiler (injecting validated facts into Markdown templates)
    #
    # PLACEHOLDER, not dead code: digest_section is deliberately nil until a Bills Digest lookup
    # exists, so every compiled summary currently gets the "No Bill Digest found." fallback defined
    # in TEMPLATES.md. See "Hooking it up to live systems" in
    # division_summary_pipeline/ARCHITECTURE.md for the exact contract a future digest integration
    # must meet (digest_link + digest_key_points, or a pre-formatted section starting "According to
    # the [Bill Digest](LINK):").
    compiled_markdown = DivisionSummaryPipeline::TemplateCompiler.compile(division, extraction, digest_section: nil)
    title = extraction.topic.presence || division_default_title

    Result.new(
      model: model_id,
      title: title,
      description: compiled_markdown,
      raw: raw_response,
      error: nil
    )
  rescue Aws::Errors::ServiceError => e
    Result.new(model: model_id, error: e.message)
  rescue StandardError => e
    Result.new(model: model_id, error: "Pipeline error: #{e.message}")
  end

  private

  attr_reader :division

  def client
    @client ||= Aws::BedrockRuntime::Client.new(region: REGION)
  end

  # The Hansard context packet for this division, built once and reused across model calls
  # (see #summarize_with).
  def hansard_packet
    @hansard_packet ||= DivisionSummaryPipeline::ContextBuilder.build(
      division,
      xml_content: @xml_content,
      context_level: :subdebate
    )
  end

  def division_default_title
    division.respond_to?(:name) ? division.name : "Division #{division.respond_to?(:number) ? division.number : ''}"
  end
end
