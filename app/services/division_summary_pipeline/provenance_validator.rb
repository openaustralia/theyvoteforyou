# frozen_string_literal: true

module DivisionSummaryPipeline
  # The distinction that matters here: `errors` stop compilation outright, `warnings` do not.
  # Anything that would put an unsupported statement in front of a reader is an error; a
  # doubt a human should look at, but which publishes nothing false on its own, is a warning.
  ValidationResult = Struct.new(
    :is_valid,
    :errors,
    :warnings,
    :requires_human_review,
    :review_reason,
    keyword_init: true
  )

  # Stage 4: asserts mechanical verbatim provenance by verifying that every extracted quote
  # exists verbatim in the source Hansard context.
  #
  # Nothing the model returned is treated as true until it is found in the transcript, because
  # a model is perfectly capable of producing a quote that reads like Hansard and was never
  # said. The check is plain substring matching on purpose: anything cleverer would start
  # accepting near-misses, and a near-miss here is a fabricated quote attributed to a real
  # politician. While mechanical verification guarantees that quotes were actually spoken,
  # it cannot verify semantic interpretation; human review of drafts remains essential.
  #
  # This stage is what makes the rest of the design safe to run at all. The LLM is allowed to
  # be wrong upstream precisely because being wrong is caught here rather than published.
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

    # The two reasoned-amendment forms that say "declining to give the bill a second reading"
    # inside a negation, and therefore mean the opposite of what a substring match suggests
    # (House of Representatives Guide to Procedures, pp. 68-69).
    NOT_DECLINING_PATTERN = /whil(?:st|e)\s+not\s+(?:declining|opposing)/i

    # The explicitly declining form from the same list.
    DECLINING_PATTERN = /declin(?:es|ing)\s+to\s+give\s+the\s+bill\s+a\s+second\s+reading/i

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

    # Every check runs even after one fails, so a reviewer sees everything wrong with a draft
    # at once rather than rerunning the pipeline to find the next problem.
    def validate
      return failure_result(["Extraction payload is missing or nil."]) unless extraction

      check_context_sufficiency
      check_context_warnings
      check_template_id
      check_routing_fence
      check_topic
      check_motion_text
      check_template_specific_rules
      check_extracted_field_provenance
      check_claims_provenance

      is_valid = errors.empty?
      if !is_valid && !requires_review
        @requires_review = true
        @review_reason = "Validation errors detected: #{errors.first(2).join('; ')}"
      end

      ValidationResult.new(
        is_valid: is_valid,
        errors: errors,
        warnings: warnings,
        requires_human_review: requires_review,
        review_reason: review_reason
      )
    end

    # Mechanically verifies that a quote or snippet exists verbatim in the source text.
    # Normalising both sides first (quotes, dashes, spacing, case) forgives typography, which
    # differs between Hansard and a model's transcription of it, and nothing else.
    #
    # No partial-match tolerance: a fabricated middle between two genuine bookends must
    # be rejected, so the whole normalised snippet has to appear as one substring.
    def self.verify_provenance?(snippet, full_text)
      norm_snippet = TextNormaliser.normalise_for_matching(snippet)
      norm_source = TextNormaliser.normalise_for_matching(full_text)

      return false if norm_snippet.empty? || norm_source.empty?

      norm_source.include?(norm_snippet)
    end

    HONORIFIC_PATTERN = /\b(mr|mrs|ms|miss|dr|senator|representative|member|hon|honourable|mp)\b/i

    # Restricts hansard_context to the lines spoken by speaker_name, so a claim's evidence
    # can only be verified against words that speaker actually said, not the whole day's
    # debate. Falls back to the full text when there's no speaker to scope by, or when the
    # text has no per-speaker "SPEECH:" tagging to filter on at all (the ContextBuilder
    # fallback path used when no matching Hansard XML was found has no such tagging: it
    # exists only for the primary source, but the quote and its date, house etc. are still
    # verifiable as a whole).
    def self.extract_speaker_text(speaker_name, full_text)
      full_text = full_text.to_s
      return full_text if speaker_name.blank? || full_text.exclude?("SPEECH:")

      chunks = full_text.split(/(?=SPEECH: )/)

      speaker_chunks = chunks.select do |chunk|
        label_line = chunk.sub(/\ASPEECH:\s*/, "").lines.first.to_s
        speaker_matches?(label_line, speaker_name)
      end

      speaker_chunks.join("\n")
    end

    def self.speaker_matches?(label_line, speaker_name)
      norm_label = TextNormaliser.normalise_for_matching(label_line)
      norm_speaker = TextNormaliser.normalise_for_matching(speaker_name)
      return true if norm_label.include?(norm_speaker)

      clean_label = clean_speaker_name(label_line)
      clean_speaker = clean_speaker_name(speaker_name)
      return false if clean_speaker.blank?
      return true if clean_label.include?(clean_speaker)

      label_tokens = clean_label.split
      speaker_tokens = clean_speaker.split
      return false if label_tokens.empty? || speaker_tokens.empty?

      # Match on surname if first names match or one side only supplied a surname
      label_tokens.last == speaker_tokens.last &&
        (label_tokens.size == 1 || speaker_tokens.size == 1 || label_tokens.first == speaker_tokens.first)
    end

    def self.clean_speaker_name(name)
      norm = TextNormaliser.normalise_for_matching(name)
      norm.gsub(HONORIFIC_PATTERN, " ")
          .gsub(/\[.*?\]/, " ")
          .gsub(/[^\w\s]/, " ")
          .gsub(/\s+/, " ")
          .strip
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

    # A warning, not an error: the orchestrator has already retried over the whole sitting
    # day by this point, and what the model did extract from a thin excerpt can still be
    # correct and fully evidenced. It is a human's call, not the pipeline's.
    def check_context_sufficiency
      return if extraction.sufficient_context

      @requires_review = true
      @review_reason = extraction.missing_context_clue || "Model reported insufficient context."
      warnings << "Context flagged as insufficient: #{review_reason}"
    end

    # Stage 1's flags for when the debate beside a division may not be the debate about it.
    # Warnings rather than errors for the same reason as insufficient context: every quote
    # still has to be found in the transcript, and an extraction built on the wrong debate is
    # something a person can spot and the code cannot. Carrying them through to the draft is
    # the point; they are invisible to a reviewer otherwise.
    def check_context_warnings
      notes = context_packet.respond_to?(:context_warnings) ? Array(context_packet.context_warnings) : []
      return if notes.empty?

      notes.each { |note| warnings << "Context warning: #{note}" }
      @requires_review = true
      @review_reason = notes.first if review_reason.blank?
    end

    def check_template_id
      return if extraction.template_id.is_a?(Integer) && extraction.template_id.between?(1, 28)

      errors << "Invalid template_id #{extraction.template_id}. Must be an integer between 1 and 28."
    end

    # Re-checks stage 2's fence, which otherwise reaches the model only as an instruction
    # (SemanticExtractor's system prompt, rule 2) with nothing verifying it was obeyed. A
    # locked-out template is always an error: the router locks one out only where it has
    # positive evidence the template is wrong, and Template 18 under a "Limitation of Debate"
    # heading is the case the whole routing stage exists to prevent. Candidates are enforced
    # on the same footing unless the decision marked them advisory (see ProceduralDecision).
    #
    # Failing here sends the draft to human review rather than discarding the extraction,
    # because a model contradicting the router means one of the two is wrong about this
    # division and the code cannot tell which.
    def check_routing_fence
      decision = context_packet&.procedural_decision
      return unless decision

      template_id = extraction.template_id
      candidates = decision.candidate_templates.to_a

      errors << "Template #{template_id} is locked out by procedural rule #{decision.rule_name}: #{decision.reason}" if decision.locked_out_templates.to_a.include?(template_id)

      return if decision.advisory_candidates || candidates.empty? || candidates.include?(template_id)

      errors << "Template #{template_id} is outside the candidates #{candidates.inspect} set by procedural " \
                "rule #{decision.rule_name}: #{decision.reason}"
    end

    def check_topic
      errors << "Field 'topic' must not be empty." if extraction.topic.blank?
    end

    # Unverifiable motion text is only a warning, unlike claim evidence: a motion is often
    # recorded in a form the surrounding transcript never repeats word for word, so failing
    # the draft on it would reject far more good summaries than bad ones.
    def check_motion_text
      if extraction.motion_text.blank?
        errors << "Field 'motion_text' must not be empty."
      elsif context_packet && context_packet.hansard_context.present?
        first_line = extraction.motion_text.strip.split("\n").first.to_s.strip
        warnings << "First line of motion text could not be verified in Hansard context: '#{first_line[0..50]}...'" if first_line.length > 20 && !self.class.verify_provenance?(first_line, context_packet.hansard_context)
      end
    end

    def check_template_specific_rules
      # Template 2's summary states the opposite thing depending on this flag: an amendment
      # declining a second reading makes a vote for it a vote against the bill proceeding.
      # Left unanswered there is no safe default, so the model must commit either way.
      errors << "Template 2 requires 'declines_second_reading' to be explicitly boolean (true or false)." if extraction.template_id == 2 && extraction.declines_second_reading.nil?

      check_declines_second_reading_against_motion

      TEMPLATE_REQUIRED_FIELDS.each do |template_id, field|
        next unless extraction.template_id == template_id
        next if extraction.public_send(field).present?

        errors << "Template #{template_id} requires '#{field}' but it was not extracted; needs human review rather than publishing a blank."
      end

      return unless [23, 24].include?(extraction.template_id) && extraction.target_name.blank? && extraction.target_electorate.blank?

      errors << "Template #{extraction.template_id} requires 'target_name' or 'target_electorate' to identify the targeted member."
    end

    # The one place the model can be caught contradicting the words it just extracted. The
    # House guide gives a closed list of the forms a reasoned amendment takes, and two of them
    # ("whilst not declining to give the bill a second reading ...", "whilst not opposing the
    # provisions of the bill ...") read as declining until the negation is noticed, while
    # "the House declines to give the bill a second reading" is unambiguous the other way.
    # Template 2's summary says the opposite thing depending on the flag, so a disagreement
    # between the flag and the motion text is worth failing on rather than publishing
    # (KNOWN_ISSUES.md, KI-11).
    def check_declines_second_reading_against_motion
      return unless extraction.template_id == 2
      return if extraction.declines_second_reading.nil?

      motion = extraction.motion_text.to_s
      not_declining = motion.match?(NOT_DECLINING_PATTERN)
      declining = motion.match?(DECLINING_PATTERN) && !not_declining

      if extraction.declines_second_reading && not_declining
        errors << "'declines_second_reading' is true but the motion text uses a \"whilst not declining/opposing\" " \
                  "form, which does not decline the second reading."
      elsif !extraction.declines_second_reading && declining
        errors << "'declines_second_reading' is false but the motion text declines to give the bill a second reading."
      end
    end

    # These facts are published verbatim, so they earn a quote's treatment rather than a
    # field's. A name printed beside a censure motion is the last place to accept a guess.
    def check_extracted_field_provenance
      EXTRACTED_TEMPLATE_FIELDS.each do |field|
        value = extraction.public_send(field)
        next if value.blank?
        next unless context_packet && context_packet.hansard_context.present?
        next if self.class.verify_provenance?(value, context_packet.hansard_context)

        errors << "Provenance check failed: '#{field}' (\"#{value[0..80]}\") was not found in Hansard source."
      end
    end

    def check_claims_provenance
      claims = extraction.mover_claims || []
      # Pure procedural votes (closure, gag, suspension, adjournment) decide only procedure, so
      # having nothing to report about underlying arguments is correct, not a gap.
      warnings << "No mover claims extracted." if claims.empty? && [22, 23, 24, 26].exclude?(extraction.template_id)

      claims.each_with_index do |claim, idx|
        errors << "Claim ##{idx + 1} has an empty claim text." if claim.claim.blank?

        if claim.evidence.blank?
          errors << "Claim ##{idx + 1} ('#{claim.claim.to_s[0..40]}...') is missing supporting evidence."
        elsif context_packet && context_packet.hansard_context.present?
          # MECHANICAL PROVENANCE ASSERTION, scoped to the claimed speaker's own words so a
          # genuine quote from one member can't be credited to another.
          speaker_context = self.class.extract_speaker_text(claim.speaker, context_packet.hansard_context)
          unless self.class.verify_provenance?(claim.evidence, speaker_context)
            attribution = claim.speaker.present? ? " attributed to '#{claim.speaker}'" : ""
            errors << "Provenance check failed: Evidence for claim ##{idx + 1}#{attribution} was not found in Hansard source: \"#{claim.evidence[0..80]}...\""
          end
        end
      end
    end
  end
end
