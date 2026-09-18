# frozen_string_literal: true

require "json"

module DivisionSummaryPipeline
  # ClaimEvidence pairs an assertion regarding a motion with a verbatim quote from Hansard.
  ClaimEvidence = Struct.new(:claim, :evidence, :speaker, keyword_init: true) do
    def to_h
      {
        claim: claim.to_s,
        evidence: evidence.to_s,
        speaker: speaker
      }
    end
  end

  # ExtractionPayload represents the structured semantic payload extracted by
  # the LLM from Hansard context. The LLM never writes final summary prose;
  # it only populates this schema.
  class ExtractionPayload
    attr_accessor :template_id, :topic, :motion_text, :mover_claims,
                  :declines_second_reading, :sufficient_context, :missing_context_clue,
                  :legacy_title, :legacy_description

    def initialize(
      template_id:,
      topic:,
      motion_text:,
      mover_claims: [],
      declines_second_reading: nil,
      sufficient_context: true,
      missing_context_clue: nil,
      legacy_title: nil,
      legacy_description: nil
    )
      @template_id = template_id.to_i
      @topic = topic.to_s
      @motion_text = motion_text.to_s
      @mover_claims = mover_claims || []
      @declines_second_reading = declines_second_reading.nil? ? nil : !!declines_second_reading
      @sufficient_context = sufficient_context.nil? ? true : !!sufficient_context
      @missing_context_clue = missing_context_clue
      @legacy_title = legacy_title
      @legacy_description = legacy_description
    end

    def legacy?
      @template_id.zero? && @legacy_description.present?
    end

    def to_h
      if legacy?
        {
          title: @legacy_title,
          description: @legacy_description
        }
      else
        {
          template_id: template_id,
          topic: topic,
          motion_text: motion_text,
          mover_claims: mover_claims.map(&:to_h),
          declines_second_reading: declines_second_reading,
          sufficient_context: sufficient_context,
          missing_context_clue: missing_context_clue
        }
      end
    end

    def to_json(options = nil)
      to_h.to_json(options)
    end

    # Parses raw JSON output from the model, handling markdown fences and key normalisation.
    def self.from_json(json_str)
      return nil if json_str.nil? || json_str.to_s.strip.empty?

      cleaned = json_str.to_s.strip
      if cleaned.start_with?("```")
        cleaned = cleaned.sub(/\A```(?:json)?\s*/i, "")
        cleaned = cleaned.sub(/```\s*\z/, "")
      end

      # Find json object boundaries if there is extra preamble
      json_match = cleaned[/\{.*\}/m]
      cleaned = json_match if json_match

      data = JSON.parse(cleaned.strip)
      from_h(data)
    rescue JSON::ParserError
      nil
    end

    # Constructs an ExtractionPayload from a Ruby hash.
    def self.from_h(data)
      return nil unless data.is_a?(Hash)

      norm_data = {}
      data.each { |k, v| norm_data[k.to_s.downcase] = v }

      tpl_id = norm_data["template_id"].to_i

      # Check for legacy title/description payload
      if tpl_id.zero? && norm_data["description"].present?
        return new(
          template_id: 0,
          topic: norm_data["title"].to_s,
          motion_text: "",
          legacy_title: norm_data["title"].to_s,
          legacy_description: norm_data["description"].to_s
        )
      end

      claims_raw = norm_data["mover_claims"] || norm_data["introducer_claims"] || []
      claims = parse_claims(claims_raw)

      declines = norm_data["declines_second_reading"]
      declines = declines.nil? ? nil : !!declines

      sufficient = norm_data.key?("sufficient_context") ? !!norm_data["sufficient_context"] : true

      new(
        template_id: tpl_id,
        topic: norm_data["topic"].to_s,
        motion_text: norm_data["motion_text"].to_s,
        mover_claims: claims,
        declines_second_reading: declines,
        sufficient_context: sufficient,
        missing_context_clue: norm_data["missing_context_clue"]
      )
    end

    def self.parse_claims(claims_raw)
      claims = []
      if claims_raw.is_a?(Array)
        claims_raw.each do |item|
          if item.is_a?(Hash)
            norm_item = {}
            item.each { |k, v| norm_item[k.to_s.downcase] = v }
            claims << ClaimEvidence.new(
              claim: norm_item["claim"].to_s,
              evidence: norm_item["evidence"].to_s,
              speaker: norm_item["speaker"]
            )
          elsif item.is_a?(String)
            claims << ClaimEvidence.new(claim: item, evidence: item)
          end
        end
      elsif claims_raw.is_a?(String)
        claims_raw.split("\n").each do |line|
          cleaned = line.strip.sub(/\A[>*]\s*/, "").strip
          claims << ClaimEvidence.new(claim: cleaned, evidence: cleaned) unless cleaned.empty?
        end
      end
      claims
    end

    # Returns the JSON Schema definition for the expected LLM output.
    def self.json_schema
      {
        "$schema": "http://json-schema.org/draft-07/schema#",
        title: "ExtractionPayload",
        type: "object",
        required: ["template_id", "topic", "motion_text", "mover_claims"],
        properties: {
          template_id: {
            type: "integer",
            minimum: 1,
            maximum: 23,
            description: "The matching parliamentary template ID (1 to 23)."
          },
          topic: {
            type: "string",
            description: "A concise 2-to-5 word description of the bill, motion, or subject."
          },
          declines_second_reading: {
            type: ["boolean", "null"],
            description: "For Template 2 only: true if the amendment explicitly seeks to decline the second reading."
          },
          mover_claims: {
            type: "array",
            description: "1 to 4 claims made by the mover, each with verbatim evidence from Hansard.",
            items: {
              type: "object",
              required: ["claim", "evidence"],
              properties: {
                claim: {
                  type: "string",
                  description: "Concise summary of the functional purpose in Australian English (-ise, -our)."
                },
                evidence: {
                  type: "string",
                  description: "Verbatim quote from the provided Hansard text proving the claim."
                },
                speaker: {
                  type: ["string", "null"],
                  description: "The name of the member who made the statement."
                }
              }
            }
          },
          motion_text: {
            type: "string",
            description: "The exact wording of the motion or amendment as put to the chamber."
          },
          sufficient_context: {
            type: "boolean",
            description: "Whether the provided excerpt had sufficient context to extract the purpose and motion."
          },
          missing_context_clue: {
            type: ["string", "null"],
            description: "Clue if context was missing (e.g. 'Mover introduced amendment on previous sitting day')."
          }
        }
      }
    end
  end
end

