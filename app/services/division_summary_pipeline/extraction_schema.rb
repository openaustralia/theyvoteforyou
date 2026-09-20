# frozen_string_literal: true

require "json"

module DivisionSummaryPipeline
  # Pairs an assertion about a motion with the verbatim Hansard quote that proves it. The
  # pairing is the whole point: `claim` is the model's own wording and is published, so it is
  # only allowed out if `evidence` survives stage 4. `speaker` narrows which part of the
  # transcript that check searches.
  ClaimEvidence = Struct.new(:claim, :evidence, :speaker, keyword_init: true) do
    def to_h
      {
        claim: claim.to_s,
        evidence: evidence.to_s,
        speaker: speaker
      }
    end
  end

  # The structured payload the LLM populates, and the full extent of what it is allowed to
  # say. Nothing outside these fields reaches a summary. Three of them are easy to misread:
  #
  # - sufficient_context / missing_context_clue: the model reporting that the excerpt was too
  #   thin, which the orchestrator answers by rebuilding the packet over the whole sitting
  #   day. Reporting the gap is wanted behaviour, not a failure.
  # - declines_second_reading: inverts what a vote for a Template 2 amendment means, so the
  #   compiled summary says the opposite thing depending on it.
  # - target_name, committee_name and the rest: the one fact a given template names, taken
  #   verbatim from Hansard. Deliberately never a party, electorate or link; those are
  #   database facts MemberResolver supplies (ARCHITECTURE.md, Data classification).
  class ExtractionPayload
    attr_accessor :template_id, :topic, :motion_text, :mover_claims,
                  :declines_second_reading, :sufficient_context, :missing_context_clue,
                  :target_name, :target_electorate, :committee_name, :regulation_name,
                  :business_name, :rearrangement_description,
                  :legacy_title, :legacy_description

    def initialize(
      template_id:,
      topic:,
      motion_text:,
      mover_claims: [],
      declines_second_reading: nil,
      sufficient_context: true,
      missing_context_clue: nil,
      target_name: nil,
      target_electorate: nil,
      committee_name: nil,
      regulation_name: nil,
      business_name: nil,
      rearrangement_description: nil,
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
      @target_name = self.class.optional_text(target_name)
      @target_electorate = self.class.optional_text(target_electorate)
      @committee_name = self.class.optional_text(committee_name)
      @regulation_name = self.class.optional_text(regulation_name)
      @business_name = self.class.optional_text(business_name)
      @rearrangement_description = self.class.optional_text(rearrangement_description)
      @legacy_title = legacy_title
      @legacy_description = legacy_description
    end

    # Replies in the shape an earlier prompt asked for: prose written by the model, with no
    # template and no evidence. Recognised only so saved responses from before the pipeline
    # existed still read back; it bypasses stages 4 and 5, so it is not a path to extend.
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
          missing_context_clue: missing_context_clue,
          target_name: target_name,
          target_electorate: target_electorate,
          committee_name: committee_name,
          regulation_name: regulation_name,
          business_name: business_name,
          rearrangement_description: rearrangement_description
        }
      end
    end

    def to_json(options = nil)
      to_h.to_json(options)
    end

    # Tolerates the wrappings models add despite being told not to (Markdown fences, a line
    # of preamble). Leniency is safe here because it only affects whether the payload parses;
    # what it claims is still checked against Hansard in stage 4.
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

    # Keys are lower-cased first because models vary the casing of field names between
    # replies, and a mis-cased key would silently read as a missing field.
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
        missing_context_clue: norm_data["missing_context_clue"],
        target_name: norm_data["target_name"],
        target_electorate: norm_data["target_electorate"],
        committee_name: norm_data["committee_name"],
        regulation_name: norm_data["regulation_name"],
        business_name: norm_data["business_name"],
        rearrangement_description: norm_data["rearrangement_description"]
      )
    end

    # Models return claims in several shapes, so all are accepted. A claim arriving without
    # its own evidence becomes its own evidence rather than being trusted: it then only
    # survives stage 4 if those exact words are genuinely in Hansard, which is usually not.
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

    # Template-specific facts are published verbatim in the compiled summary, so blank
    # values collapse to nil and surrounding whitespace is stripped rather than published.
    def self.optional_text(value)
      value.to_s.strip.presence
    end

    # The JSON Schema for the expected LLM output. It mirrors this class field for field and
    # lives beside it so the two cannot drift; the descriptions double as per-field
    # instructions to the model.
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
          target_name: {
            type: ["string", "null"],
            description: "Name of the member or minister the motion targets (templates 10 and 23), verbatim from the Hansard text; null if not stated."
          },
          target_electorate: {
            type: ["string", "null"],
            description: "Electorate of the member the motion targets (template 23, e.g. 'Dickson' from 'the honourable member for Dickson'), verbatim; null if not stated."
          },
          committee_name: {
            type: ["string", "null"],
            description: "Name of the committee the motion concerns (template 13), verbatim from the Hansard text; null if not stated."
          },
          regulation_name: {
            type: ["string", "null"],
            description: "Name of the legislative instrument the motion would disallow (template 9), verbatim from the Hansard text; null if not stated."
          },
          business_name: {
            type: ["string", "null"],
            description: "Name of the business withdrawn from the Notice Paper (template 20), verbatim from the Hansard text; null if not stated."
          },
          rearrangement_description: {
            type: ["string", "null"],
            description: "What the rearrangement of business does, in the motion's operative words (template 19); null if not stated."
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

