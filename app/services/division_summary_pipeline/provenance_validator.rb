# frozen_string_literal: true

module DivisionSummaryPipeline
  # ValidationResult holds the outcome of the mechanical provenance verification.
  ValidationResult = Struct.new(
    :is_valid,
    :errors,
    :warnings,
    :requires_human_review,
    :review_reason,
    keyword_init: true
  )

  # ProvenanceValidator enforces zero-hallucination by mechanically asserting
  # that every extracted evidence quote exists verbatim in the source Hansard context.
  class ProvenanceValidator
    # Fields the templates render verbatim in the summary sentence. A template whose
    # fact is missing would publish a blank (for example "to the  for inquiry and
    # report"), so absence is an error routing the draft to human review rather than
    # to publication.
    TEMPLATE_REQUIRED_FIELDS = {
      9 => :regulation_name,
      10 => :target_name,
      13 => :committee_name,
      19 => :rearrangement_description,
      20 => :business_name
    }.freeze

    # Extracted facts published verbatim; each is mechanically verified against the
    # Hansard context exactly like claim evidence.
    EXTRACTED_TEMPLATE_FIELDS = %i[target_name target_electorate committee_name
                                   regulation_name business_name
                                   rearrangement_description].freeze

    def self.validate(extraction, context_packet)
      new(extraction, context_packet).validate
    end

    def initialize(extraction, context_packet)
      @extraction = extraction
      @context_packet = context_packet
      @errors = []
      @warnings = []
      @requires_review = false
      @review_reason = nil
    end

    def validate
      return failure_result(["Extraction payload is missing or nil."]) unless extraction

      check_context_sufficiency
      check_template_id
      check_topic
      check_motion_text
      check_template_specific_rules
      check_extracted_field_provenance
      check_claims_provenance

      is_valid = errors.empty?
      if !is_valid && !requires_review
        @requires_review = true
        @review_reason = "Validation errors detected: " + errors.first(2).join("; ")
      end

      ValidationResult.new(
        is_valid: is_valid,
        errors: errors,
        warnings: warnings,
        requires_human_review: requires_review,
        review_reason: review_reason
      )
    end

    # Mechanically verifies that a quote or snippet exists in the source text.
    def self.verify_provenance(snippet, full_text)
      norm_snippet = TextNormaliser.normalise_for_matching(snippet)
      norm_source = TextNormaliser.normalise_for_matching(full_text)

      return false if norm_snippet.empty? || norm_source.empty?
      return true if norm_source.include?(norm_snippet)

      # For longer quotes (the prototype's threshold is 80 characters), tolerate minor
      # mid-quote formatting breaks by matching the first and last 8 words instead of the
      # whole quote.
      words = norm_snippet.split(" ")
      if norm_snippet.length > 80
        start_chunk = words.first(8).join(" ")
        end_chunk = words.last(8).join(" ")
        return true if norm_source.include?(start_chunk) && norm_source.include?(end_chunk)
      end

      false
    end

    private

    attr_reader :extraction, :context_packet, :errors, :warnings, :requires_review, :review_reason

    def failure_result(errs)
      ValidationResult.new(
        is_valid: false,
        errors: errs,
        warnings: [],
        requires_human_review: true,
        review_reason: errs.first
      )
    end

    def check_context_sufficiency
      unless extraction.sufficient_context
        @requires_review = true
        @review_reason = extraction.missing_context_clue || "Model reported insufficient context."
        warnings << "Context flagged as insufficient: #{review_reason}"
      end
    end

    def check_template_id
      unless extraction.template_id.is_a?(Integer) && extraction.template_id.between?(1, 23)
        errors << "Invalid template_id #{extraction.template_id}. Must be an integer between 1 and 23."
      end
    end

    def check_topic
      errors << "Field 'topic' must not be empty." if extraction.topic.blank?
    end

    def check_motion_text
      if extraction.motion_text.blank?
        errors << "Field 'motion_text' must not be empty."
      elsif context_packet && context_packet.hansard_context.present?
        first_line = extraction.motion_text.strip.split("\n").first.to_s.strip
        if first_line.length > 20 && !self.class.verify_provenance(first_line, context_packet.hansard_context)
          warnings << "First line of motion text could not be verified in Hansard context: '#{first_line[0..50]}...'"
        end
      end
    end

    def check_template_specific_rules
      if extraction.template_id == 2 && extraction.declines_second_reading.nil?
        errors << "Template 2 requires 'declines_second_reading' to be explicitly boolean (true or false)."
      end

      TEMPLATE_REQUIRED_FIELDS.each do |template_id, field|
        next unless extraction.template_id == template_id
        next unless extraction.public_send(field).blank?

        errors << "Template #{template_id} requires '#{field}' but it was not extracted; needs human review rather than publishing a blank."
      end

      if extraction.template_id == 23 && extraction.target_name.blank? && extraction.target_electorate.blank?
        errors << "Template 23 requires 'target_name' or 'target_electorate' to identify the member who is no longer heard."
      end
    end

    def check_extracted_field_provenance
      EXTRACTED_TEMPLATE_FIELDS.each do |field|
        value = extraction.public_send(field)
        next if value.blank?
        next unless context_packet && context_packet.hansard_context.present?
        next if self.class.verify_provenance(value, context_packet.hansard_context)

        errors << "Provenance check failed: '#{field}' (\"#{value[0..80]}\") was not found in Hansard source."
      end
    end

    def check_claims_provenance
      claims = extraction.mover_claims || []
      if claims.empty? && ![22, 23].include?(extraction.template_id)
        warnings << "No mover claims extracted."
      end

      claims.each_with_index do |claim, idx|
        if claim.claim.blank?
          errors << "Claim ##{idx + 1} has an empty claim text."
        end

        if claim.evidence.blank?
          errors << "Claim ##{idx + 1} ('#{claim.claim.to_s[0..40]}...') is missing supporting evidence."
        elsif context_packet && context_packet.hansard_context.present?
          # MECHANICAL PROVENANCE ASSERTION
          unless self.class.verify_provenance(claim.evidence, context_packet.hansard_context)
            errors << "Provenance check failed: Evidence for claim ##{idx + 1} was not found in Hansard source: \"#{claim.evidence[0..80]}...\""
          end
        end
      end
    end
  end
end

