# frozen_string_literal: true

module DivisionSummaryPipeline
  # Stage 2's answer, kept to the contract the later stages enforce. What a reviewer needs to
  # know about why the router decided it is held apart, in `diagnostic`, and nothing downstream
  # branches on it.
  #
  # - :deterministic, the question settles the template (template_id) and nothing else is allowed.
  # - :constrained, the question narrows the choice to allowed_templates and the model picks
  #   one of them; anything else fails validation.
  # - :advisory, no rule matched, so allowed_templates is only a default the model may depart
  #   from; reaching that point means an extractor that recognises the motion knows more than
  #   the router does.
  #
  # forbidden_templates are refused in every mode. The router forbids a template only where it
  # has positive evidence it is wrong, above all Template 18 under a "Limitation of Debate"
  # heading, the misreading Stage 2 exists to prevent.
  RoutingDecision = Data.define(:template_id, :allowed_templates, :forbidden_templates, :mode, :diagnostic)

  class RoutingDecision
    Diagnostic = Data.define(:rule_name, :reason)

    def self.settled(template_id, rule_name:, reason:)
      new(template_id: template_id, allowed_templates: [template_id], forbidden_templates: [],
          mode: :deterministic, diagnostic: Diagnostic.new(rule_name: rule_name, reason: reason))
    end

    def self.fenced(allowed, rule_name:, reason:, forbidden: [])
      new(template_id: nil, allowed_templates: allowed, forbidden_templates: forbidden, mode: :constrained,
          diagnostic: Diagnostic.new(rule_name: rule_name, reason: reason))
    end

    def self.default(allowed, rule_name:, reason:, forbidden: [])
      new(template_id: nil, allowed_templates: allowed, forbidden_templates: forbidden, mode: :advisory,
          diagnostic: Diagnostic.new(rule_name: rule_name, reason: reason))
    end

    def deterministic?
      mode == :deterministic
    end

    def advisory?
      mode == :advisory
    end

    delegate :rule_name, :reason, to: :diagnostic

    def forbids?(template_id)
      forbidden_templates.include?(template_id)
    end

    # Whether choosing template_id breaks the fence: always for a forbidden template, and for
    # anything outside allowed_templates unless the list is only advisory.
    def refuses?(template_id)
      return true if forbids?(template_id)
      return false if advisory? || allowed_templates.empty?

      allowed_templates.exclude?(template_id)
    end
  end
end
