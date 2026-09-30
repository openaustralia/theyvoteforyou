# frozen_string_literal: true

module DivisionSummaryPipeline
  # The distinction that matters: `errors` stop compilation outright, `warnings` do not. Anything
  # that would put an unsupported statement in front of a reader is an error; a doubt a person
  # should look at, but which publishes nothing false on its own, is a warning. `evidence` is
  # what the summary may quote, built only from references that resolved.
  ValidationResult = Data.define(:errors, :warnings, :evidence) do
    def valid?
      errors.empty?
    end

    def requires_human_review?
      errors.any? || warnings.any?
    end
  end

  # Stage 4: turns the model's references into Hansard's own text, and refuses what does not
  # resolve.
  #
  # Nothing the model returned is treated as true until it points at a unit of the transcript
  # that says it. Since the model only ever returns IDs, what can go wrong is pointing at the
  # wrong thing: a sentence another member spoke, words the mover quoted from someone else, the
  # motion itself instead of an explanation of it, a phrase that is not in the unit named. Those
  # references are dropped, with a warning a reviewer sees, so the draft prints less rather than
  # anything unsupported.
  #
  # What the summary cannot do without is an error instead: the operative motion, a fact the
  # template names, Template 2's declines_second_reading, and a template Stage 2's fence allows.
  # There is deliberately no path by which a missing motion is filled in from anything but
  # Hansard.
  #
  # This proves the quoted words were said, where and by whom. It cannot prove the model chose the
  # most representative sentences, which is why every draft is still reviewed by a person.
  class ProvenanceValidator
    # The two reasoned-amendment forms that say "declining to give the bill a second reading"
    # inside a negation, and therefore mean the opposite of what a substring match suggests
    # (House of Representatives Guide to Procedures, pp. 68-69), and the explicitly declining form.
    NOT_DECLINING_PATTERN = /whil(?:st|e)\s+not\s+(?:declining|opposing)/i
    DECLINING_PATTERN = /declin(?:es|ing)\s+to\s+give\s+the\s+bill\s+a\s+second\s+reading/i

    UNIDENTIFIED_SPEAKER = "The mover was not identified by rule, so the explanation's speaker was chosen by the model."

    def self.validate(extraction, context_packet)
      new(extraction, context_packet).validate
    end

    def initialize(extraction, context_packet)
      @extraction = extraction
      @packet = context_packet
      @errors = []
      @warnings = []
    end

    # Every check runs even after one fails, so a reviewer sees everything wrong with a draft at
    # once rather than rerunning the pipeline to find the next problem.
    def validate
      return ValidationResult.new(errors: ["The model's reply could not be read."], warnings: [], evidence: Evidence.empty) unless extraction

      note_context
      check_template
      evidence = Evidence.new(introduction: introduction, motion: check_motion, question: question,
                              explanations: explanations, facts: facts, mover: packet.mover&.member,
                              limitation: limitation, circulation: packet.circulation)
      check_declines_second_reading(evidence)
      ValidationResult.new(errors: errors, warnings: warnings, evidence: evidence)
    end

    private

    attr_reader :extraction, :packet, :errors, :warnings

    delegate :transcript, to: :packet

    def template_id
      extraction.template_id
    end

    def catalogue_entry
      TemplateCatalogue[template_id]
    end

    # Stage 1's doubts about the debate, and the model's report of what it could not find. Both
    # are warnings: every quote still has to resolve, and an extraction built on the wrong debate
    # is something a person can spot and the code cannot.
    def note_context
      packet.context_warnings.each { |note| warnings << "Context warning: #{note}" }
      extraction.missing.each do |kind|
        warnings << "The model reported this evidence missing: #{kind} (#{ExtractionPayload::MISSING_EVIDENCE[kind]})."
      end
    end

    # Re-checks Stage 2's fence, which otherwise reaches the model only as an instruction. A
    # model contradicting the router means one of the two is wrong about this division and the
    # code cannot tell which, so the draft goes to a person.
    def check_template
      unless TemplateCatalogue.valid?(template_id)
        errors << "Invalid template_id #{template_id.inspect}. Must be an integer from 1 to #{TemplateCatalogue::IDS.last}."
        return
      end

      routing = packet.routing
      return unless routing&.refuses?(template_id)

      fence = routing.forbids?(template_id) ? "is forbidden" : "is outside the allowed templates #{routing.allowed_templates.inspect}"
      errors << "Template #{template_id} #{fence} by procedural rule #{routing.rule_name}: #{routing.reason}"
    end

    def question
      units = transcript.question_units
      if units.empty?
        warnings << "The chair's statement putting the question was not recorded before the division, so the " \
                    "summary cannot quote it."
        return nil
      end
      passage(units.map(&:id), found_by: :rule)
    end

    def introduction
      speech = packet.mover_speech
      ids = speech ? transcript.last_move_units(speech, :move).map(&:id) : []
      passage(ids, found_by: :rule)
    end

    # Found by Stage 1 outside the transcript (ContextPacket#limitation_statement), so there are
    # no units to resolve: the text is already Hansard's own sentence.
    def limitation
      statement = packet.limitation_statement
      return nil unless statement

      Evidence::Excerpt.new(text: statement[:text], unit_ids: [], speaker: statement[:speaker],
                            speaker_gid: statement[:speaker_gid], time: statement[:time], date: nil, found_by: :rule)
    end

    # The terms moved: found by Stage 1 in the mover's speech, or failing that the amendments the
    # chair put, as the chair's statement printed them; failing both, the paragraphs the model
    # pointed at, if they are one unbroken run of one speech; failing that, nothing, which is only
    # acceptable when the chair's question states its own terms ("That the House do now adjourn",
    # proposed by the Speaker with no mover). A question that only refers to a motion with no
    # motion to quote leaves the summary unable to say what was decided.
    def check_motion
      speech = packet.mover_speech
      rule_ids = speech ? transcript.last_move_units(speech, :motion).map(&:id) : []
      rule_ids = transcript.question_terms_units.map(&:id) if rule_ids.empty?
      if rule_ids.any?
        warnings << "The model's motion references were ignored: Stage 1 found the motion by rule." if extraction.references.motion.any?
        return passage(rule_ids, found_by: :rule)
      end

      from_model = model_motion
      return from_model if from_model
      return nil unless packet.question_by_reference?

      errors << "The operative motion could not be found in Hansard: the question refers to a motion (\"" \
                "#{packet.speaker_question.to_s.strip[0, 120]}\") whose terms are not in the transcript. The " \
                "summary cannot say what was decided without them."
      nil
    end

    def model_motion
      ids = extraction.references.motion
      return nil if ids.empty?

      units = ids.map { |id| transcript.unit(id) }
      if (putting = units.compact.find { |unit| chair_form?(unit.text) })
        warnings << "The model's motion reference #{putting.id} is the chair putting or deciding a question, not the " \
                    "terms moved, so it was not used."
        return nil
      end
      if units.any?(&:nil?) || units.any? { |unit| unit.kind == :chair }
        warnings << "The model's motion references #{ids.inspect} do not all point at paragraphs of a speech, so they were not used."
        return nil
      end

      passages = transcript.passages(ids)
      if passages.size != 1
        warnings << "The model's motion references #{ids.inspect} are not one unbroken passage, so they were not used."
        return nil
      end
      Evidence::Excerpt.from_passage(passages.first, found_by: :model)
    end

    # The chair's own forms of words, which are never the terms of a motion whoever the transcript
    # says spoke them: the chair's statement is not always recognised as the chair's, and at Senate
    # 18 August 2026 #16 a draft printed "The question now is that amendments ... be agreed to." as
    # the amendment moved (KI-42).
    def chair_form?(text)
      text.match?(ChairStatement::QUESTION) || text.strip.match?(ChairStatement::DECIDED)
    end

    # The mover's own sentences, in the order spoken. A reference to anything else is dropped
    # rather than failing the draft: the motion is printed separately and is not an explanation
    # of itself, and neither another member's words nor words the mover quoted (a :quotation
    # unit, KI-38) are the mover's.
    def explanations
      ids = extraction.references.explanation
      return [] if ids.empty?

      unless catalogue_entry&.explains
        warnings << "The model gave explanation references for a template that prints none; they were ignored."
        return []
      end

      kept = ids.select { |id| explanation_unit?(id) }
      if kept.size > ExtractionPrompt::MAXIMUM_EXPLANATION_SENTENCES
        warnings << "The model gave #{kept.size} explanation sentences; only the first " \
                    "#{ExtractionPrompt::MAXIMUM_EXPLANATION_SENTENCES} in the order spoken are quoted."
        kept = kept.sort_by { |id| unit_order(id) }.first(ExtractionPrompt::MAXIMUM_EXPLANATION_SENTENCES)
      end
      warnings << UNIDENTIFIED_SPEAKER if kept.any? && packet.mover.nil? && packet.circulation.nil?
      transcript.passages(kept).map { |passage| Evidence::Excerpt.from_passage(passage, found_by: :model) }
    end

    def explanation_unit?(id)
      unit = transcript.unit(id)
      problem = if unit.nil? then "is not in the transcript"
                elsif unit.kind != :prose then "is #{unit.kind} text, not the mover's own words"
                elsif !by_mover?(transcript.speech_of(unit)) then "was spoken by #{transcript.speech_of(unit).label}, not the mover"
                end
      warnings << "Explanation reference #{id} #{problem}, so it was not quoted." if problem
      problem.nil?
    end

    # With no mover, amendments the chair put are explained only by the member who circulated them,
    # and a party circulating them is no speaker at all: at Senate 18 August 2026 #4 a model offered
    # the minister's speech for the bill as the case for the Greens' amendments rejecting it.
    def by_mover?(speech)
      mover = packet.mover
      return by_circulator?(speech) if mover.nil? && packet.circulation
      return true if mover.nil?

      mover_gid = mover.speech&.dig(:speaker_gid).presence || mover.member&.member&.gid
      return speech.speaker_gid == mover_gid if speech.speaker_gid.present? && mover_gid.present?

      MemberResolver.same_speaker?(speech.speaker, mover.member&.name.presence || mover.speech&.dig(:speaker))
    end

    def by_circulator?(speech)
      member = packet.circulation.member
      return false unless member&.member
      return speech.speaker_gid == member.member.gid if speech.speaker_gid.present?

      MemberResolver.same_speaker?(speech.speaker, member.name)
    end

    def unit_order(id)
      unit = transcript.unit(id)
      [unit.speech_number, unit.index]
    end

    # The facts this template names, each found inside the unit the model pointed at. A required
    # one that is missing or does not resolve is an error, since the summary sentence would
    # otherwise have a blank where a name belongs.
    def facts
      entry = catalogue_entry
      return {} unless entry

      found = entry.facts.keys.each_with_object({}) do |name, resolved|
        reference = extraction.references.facts[name]
        next unless reference

        anchor = transcript.anchor(reference.unit, reference.text)
        if anchor.problem
          warnings << "Fact '#{name}' (\"#{reference.text.to_s[0, 80]}\" in #{reference.unit}) #{anchor_problem(anchor.problem)}, so it was not used."
          next
        end
        speech = transcript.speech_of(anchor.unit)
        resolved[name] = Evidence::Excerpt.new(text: anchor.text, unit_ids: [anchor.unit.id], speaker: speech.speaker,
                                               speaker_gid: speech.speaker_gid, time: speech.time, date: speech.date,
                                               found_by: :model)
      end
      check_required_facts(entry, found)
      found
    end

    def anchor_problem(problem)
      { no_such_unit: "points at a unit that is not in the transcript", empty: "gave no words to find",
        not_found: "is not in that unit", ambiguous: "reads differently in different places in that unit" }
        .fetch(problem)
    end

    def check_required_facts(entry, found)
      entry.requires.each do |requirement|
        alternatives = Array(requirement)
        next if alternatives.any? { |name| found.key?(name) }

        errors << "Template #{entry.id} requires #{alternatives.map { |name| "'#{name}'" }.join(' or ')} but it was not " \
                  "found in Hansard; needs human review rather than publishing a blank."
      end
    end

    # Template 2's summary says the opposite thing depending on this flag. Left unanswered
    # there is no safe default, and a flag that contradicts the amendment's own words is the one
    # place the model can be caught out (KNOWN_ISSUES.md, KI-11).
    def check_declines_second_reading(evidence)
      return unless template_id == 2

      declines = extraction.declines_second_reading
      if declines.nil?
        errors << "Template 2 requires 'declines_second_reading' to be explicitly boolean (true or false)."
        return
      end

      motion = evidence.motion_text.presence || packet.speaker_question.to_s
      not_declining = motion.match?(NOT_DECLINING_PATTERN)
      if declines && not_declining
        errors << "'declines_second_reading' is true but the motion uses a \"whilst not declining/opposing\" form, " \
                  "which does not decline the second reading."
      elsif !declines && !not_declining && motion.match?(DECLINING_PATTERN)
        errors << "'declines_second_reading' is false but the motion declines to give the bill a second reading."
      end
    end

    def passage(ids, found_by:)
      found = transcript.passages(ids)
      return nil if found.empty?

      Evidence::Excerpt.from_passage(found.first, found_by: found_by) if found.size == 1
    end
  end
end
