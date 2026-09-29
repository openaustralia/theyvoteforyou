# frozen_string_literal: true

require "json"

module DivisionSummaryPipeline
  # What the model answers, and the full extent of what it is allowed to say. It has two parts,
  # kept apart because they are different kinds of thing:
  #
  # - Interpretation: decisions only the model can make by understanding the debate. Which
  #   template fits, whether a second reading amendment declines the bill a second reading, and
  #   which evidence it could not find. These steer the program; none of them is published text.
  # - References: where the evidence is, as IDs of Transcript units. The mover's explanation is
  #   a list of sentence IDs; the motion is a list of paragraph IDs, needed only when Stage 1
  #   could not find it by rule; each fact a template names (a committee, a regulation, the
  #   member a motion targets) is a unit ID and the words to find inside that unit.
  #
  # Nothing the model writes is ever printed. Stage 4 turns references into Hansard's own text,
  # and a reference it cannot resolve is not quoted at all. There is deliberately no field for a
  # topic, a claim, a motion or a note in the model's own words: an AI that can select but not
  # write cannot put words in anyone's mouth.
  class ExtractionPayload
    # missing: evidence the model looked for and could not find in the transcript, from
    # MISSING_EVIDENCE. Non-empty asks the orchestrator for a wider packet.
    Interpretation = Data.define(:template_id, :declines_second_reading, :missing)

    # facts maps a fact name (TemplateCatalogue::ALL_FACTS) to a FactReference.
    References = Data.define(:explanation, :motion, :facts)

    FactReference = Data.define(:unit, :text)

    MISSING_EVIDENCE = {
      "operative_motion" => "the terms of the motion or amendment being decided",
      "mover_speech" => "the speech in which the mover moved it (only a reference to it is here)",
      "target" => "who the motion is directed at",
      "committee" => "the committee a matter is referred to",
      "regulation" => "the legislative instrument a motion would disallow",
      "business" => "the business being withdrawn",
      "rearrangement" => "what a rearrangement of business does"
    }.freeze

    attr_reader :interpretation, :references

    def initialize(interpretation:, references:)
      @interpretation = interpretation
      @references = references
    end

    delegate :template_id, :declines_second_reading, :missing, to: :interpretation

    # Tolerates the wrappings models add despite being told not to (Markdown fences, a line of
    # preamble), and nothing else. Leniency is safe here because it only affects whether the
    # reply parses; every reference in it is still checked against the transcript in stage 4.
    def self.from_json(json_str)
      return nil if json_str.blank?

      cleaned = json_str.to_s.strip.sub(/\A```(?:json)?\s*/i, "").sub(/```\s*\z/, "")
      cleaned = cleaned[/\{.*\}/m] || cleaned
      from_h(JSON.parse(cleaned))
    rescue JSON::ParserError
      nil
    end

    # Keys are lower-cased first because models vary the casing of field names between replies,
    # and a mis-cased key would silently read as a missing field.
    def self.from_h(data)
      return nil unless data.is_a?(Hash)

      data = downcase_keys(data)
      interpretation = downcase_keys(data["interpretation"])
      references = downcase_keys(data["references"])
      return nil unless interpretation

      new(
        interpretation: Interpretation.new(
          template_id: interpretation["template_id"].to_i,
          declines_second_reading: optional_boolean(interpretation["declines_second_reading"]),
          missing: Array(interpretation["missing"]).map { |item| item.to_s.strip.downcase } & MISSING_EVIDENCE.keys
        ),
        references: References.new(
          explanation: unit_ids(references&.dig("explanation")),
          motion: unit_ids(references&.dig("motion")),
          facts: fact_references(references&.dig("facts"))
        )
      )
    end

    def self.downcase_keys(hash)
      hash.to_h { |key, value| [key.to_s.downcase, value] } if hash.is_a?(Hash)
    end

    def self.unit_ids(value)
      Array(value).map { |id| id.to_s.strip.upcase }.reject(&:empty?)
    end

    # Only facts some template names are read; anything else the model adds is ignored.
    def self.fact_references(value)
      facts = downcase_keys(value) || {}
      TemplateCatalogue::ALL_FACTS.keys.each_with_object({}) do |name, found|
        reference = downcase_keys(facts[name.to_s])
        next unless reference && reference["unit"].present? && reference["text"].present?

        found[name] = FactReference.new(unit: reference["unit"].to_s.strip.upcase, text: reference["text"].to_s)
      end
    end

    TRUTHY_STRINGS = %w[true yes y 1].freeze
    FALSEY_STRINGS = %w[false no n 0].freeze

    # Three-state on purpose: true, false, and "the model did not answer", which are three
    # different things here. `declines_second_reading` inverts what a Template 2 summary says,
    # so `false` has to survive as `false` rather than collapsing into the same value as `true`
    # (KNOWN_ISSUES.md, KI-15), and ProvenanceValidator refuses a nil there rather than guessing.
    # Models return these as JSON booleans most of the time and as the strings "true"/"false"
    # or "yes"/"no" often enough to be worth accepting; anything else is nil, i.e. unanswered.
    def self.optional_boolean(value)
      return value if [true, false].include?(value)

      text = value.to_s.strip.downcase
      return true if TRUTHY_STRINGS.include?(text)
      return false if FALSEY_STRINGS.include?(text)

      nil
    end

    def to_h
      {
        interpretation: interpretation.to_h,
        references: {
          explanation: references.explanation,
          motion: references.motion,
          facts: references.facts.transform_values(&:to_h)
        }
      }
    end

    # The JSON Schema the model is given. It mirrors this class and lives beside it so the two
    # cannot drift; the descriptions double as per-field instructions.
    def self.json_schema
      unit_ids = { type: "array", items: { type: "string", pattern: "^S\\d+\\.\\d+$" } }
      {
        "$schema": "http://json-schema.org/draft-07/schema#",
        title: "ExtractionPayload",
        type: "object",
        required: %w[interpretation references],
        properties: {
          interpretation: {
            type: "object",
            required: %w[template_id missing],
            properties: {
              template_id: { type: "integer", minimum: 1, maximum: TemplateCatalogue::IDS.last,
                             description: "The template that fits the question being decided." },
              declines_second_reading: { type: %w[boolean null],
                                         description: "Template 2 only: whether the amendment declines to give the " \
                                                      "bill a second reading." },
              missing: { type: "array", items: { enum: MISSING_EVIDENCE.keys },
                         description: "Evidence you looked for and could not find in <hansard_context>." }
            }
          },
          references: {
            type: "object",
            required: %w[explanation],
            properties: {
              explanation: unit_ids.merge(description: "IDs of sentences in which the mover explains the motion."),
              motion: unit_ids.merge(description: "Only when <motion_as_moved> says the terms were not found: IDs " \
                                                  "of the paragraphs holding the terms moved."),
              facts: {
                type: "object",
                properties: TemplateCatalogue::ALL_FACTS.to_h do |name, description|
                  [name, { type: "object", required: %w[unit text], description: description,
                           properties: { unit: { type: "string" }, text: { type: "string" } } }]
                end
              }
            }
          }
        }
      }
    end
  end
end
