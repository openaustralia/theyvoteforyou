# frozen_string_literal: true

module DivisionSummaryPipeline
  # The words the model is given: a fixed system prompt, and a user prompt built from one
  # ContextPacket. Treat the system prompt as source code. Editing a rule changes every future
  # extraction, and several rules are load-bearing: rule 5 is why an explanation is only ever
  # the mover's own sentences, rule 7 is the closed list KI-11 relies on, rule 9 restates the
  # guillotine trap Stage 2 fences, and rule 8 keeps member details out of the model's hands
  # because MemberResolver looks them up in the database.
  module ExtractionPrompt
    MAXIMUM_EXPLANATION_SENTENCES = 6

    module_function

    # Tagged sections rather than prose: models attend to delimited blocks more reliably, and
    # the question leads because rule 1 tells the model to read everything else in light of it.
    def user_prompt(packet)
      sections = []
      sections << tag("speaker_question", packet.speaker_question.to_s.strip)
      sections << tag("division_metadata", metadata_lines(packet).join("\n"))
      sections << tag("procedural_routing_guidance", routing_note(packet.routing)) if packet.routing
      # Stage 1 can tell when the speeches beside a division may not be the debate about it.
      # Passing that on lets the model report missing evidence instead of reading unrelated
      # speeches as the argument for this vote.
      sections << tag("context_warnings", packet.context_warnings.map { |warning| "- #{warning}" }.join("\n")) if packet.context_warnings.present?
      sections << tag("motion_as_moved", motion_note(packet))
      sections << tag("hansard_context", "#{packet.transcript.prompt_text}\nDIVISION [#{packet.facts.time}]")
      sections.join("\n\n")
    end

    def tag(name, body)
      "<#{name}>\n#{body}\n</#{name}>"
    end

    def metadata_lines(packet)
      facts = packet.facts
      ["Date: #{facts.date}", "House: #{facts.chamber}", "Time: #{facts.time}",
       "Division Title: #{TextNormaliser.clean_text(packet.heading)}",
       "Votes: #{facts.aye_votes} Yes - #{facts.no_votes} No"]
    end

    # An advisory shortlist is not enforced by ProvenanceValidator, so the model is told it is
    # only a default; otherwise "MUST" turns the general-motion fallback into a fence nothing
    # checks (KNOWN_ISSUES.md, KI-23).
    def routing_note(routing)
      note = "Allowed templates: [#{routing.allowed_templates.join(', ')}]."
      note += if routing.deterministic?
                " The question settles this: set template_id to #{routing.template_id}."
              elsif routing.advisory?
                " These are a default, not a constraint: choose another template if the <speaker_question> " \
                  "or <motion_as_moved> clearly fits it better."
              else
                " Choose one of these."
              end
      note += " Forbidden templates: [#{routing.forbidden_templates.join(', ')}]." if routing.forbidden_templates.any?
      note
    end

    # What Stage 1 found by rule, so the model knows the motion is settled and which speaker's
    # sentences can be an explanation.
    def motion_note(packet)
      speech = packet.mover_speech
      name = packet.mover&.member&.name.presence || speech&.label
      return "The terms moved were not found by rule. #{no_motion_instruction(packet)}" unless speech

      introduction = packet.transcript.last_move_units(speech, :move).map(&:id)
      terms = packet.transcript.last_move_units(speech, :motion).map(&:id)
      lines = ["Moved by: #{name} (speech S#{speech.number})."]
      lines << "Introduced in: #{introduction.join(', ')}." if introduction.any?
      lines << if terms.any?
                 "Terms moved: #{terms.join(', ')}. The motion is settled; leave references.motion empty."
               else
                 "The terms moved were not found by rule. #{no_motion_instruction(packet)}"
               end
      lines << "An explanation can only be sentences #{name} spoke."
      lines.join("\n")
    end

    # Told to report the terms missing whatever the question, a model reported them missing for
    # a question that is the whole motion, and the orchestrator widened to the whole sitting day
    # looking for terms that do not exist (ContextPacket#question_states_motion?).
    def no_motion_instruction(packet)
      if packet.question_states_motion?
        return "The <speaker_question> is the whole motion, so there are no separate terms to find: leave " \
               "references.motion empty and do not report \"operative_motion\" as missing."
      end

      "If the terms of the motion or amendment being decided are in <hansard_context>, list the IDs of the " \
        "paragraphs that hold them, in order, in references.motion. If they are not, leave it empty and report " \
        "\"operative_motion\" as missing."
    end

    def system_prompt
      <<~PROMPT
        You are the Evidence Selector for They Vote For You (theyvoteforyou.org.au), a project of the
        non-partisan OpenAustralia Foundation. You read Australian parliamentary records and answer in
        strict JSON. You never write text for publication: no titles, summaries, paraphrases or quotes.
        You make a few decisions, and you point at evidence by the IDs printed in the transcript. The
        program then prints Hansard's own words from those IDs, so anything you do not point at is not
        printed, and nothing you write is printed.

        HOW THE TRANSCRIPT IS SHOWN
        Every unit of <hansard_context> starts with an ID in square brackets. A member's own words are
        one sentence per ID ("[S3.4] ..."). Other units are whole paragraphs, marked with their kind:
        "move" is the member saying "I move ...", "motion" is the terms they moved, and "chair" is the
        chair putting the question for this division.

        1. ANCHOR ON THE SPEAKER'S QUESTION:
           <speaker_question> is what the division decided. Read everything else in light of it.

        2. OBEY PROCEDURAL ROUTING GUIDANCE:
           Choose template_id as <procedural_routing_guidance> says. Never choose a forbidden template.

        3. THE TEMPLATE CATALOGUE (template_id 1 to #{TemplateCatalogue::IDS.last}):
        #{catalogue_lines}

        4. THE MOTION:
           <motion_as_moved> says what Stage 1 found by rule. When it lists the terms moved, the motion is
           settled and references.motion stays empty. Otherwise follow what it tells you.

        5. THE MOVER'S EXPLANATION:
           references.explanation lists the IDs of up to #{MAXIMUM_EXPLANATION_SENTENCES} sentences in which the
           mover explains what the motion does or why they moved it, in the order they were spoken.
           - Only the mover's own sentences, never another member's, and never a "move", "motion" or
             "chair" unit. The terms of the motion are printed separately; they are not an explanation of
             themselves.
           - If the mover gave no explanation (the speech is only the move and its terms, or it was moved
             formally), return an empty list. Do not fill it with anything else.
           - Choose the sentences that state the mover's case plainly: what the motion would do and the
             reasons given. Select fairly, not to make the case look stronger or weaker.
           - Scope to what the vote itself decides, never the subject it happens to sit under:
             Template 8 (production of documents): why the documents should be produced, not their subject.
             Template 17 (suspension of standing orders): why the rules should be set aside so something can
             happen now, not the merits of that matter.
             Template 18 (limitation of debate): the time limit and the remaining stages, not the business.
             Template 9 (disallowance): what the regulation does and why it should stop having legal force.
             Templates 22, 23, 24 and 26 print no explanation: return an empty list.

        6. NEUTRALITY IS NOT OPTIONAL:
           Never favour or disfavour any party, candidate or position in what you choose or report.

        7. TEMPLATE 2 (SECOND READING AMENDMENT):
           If template_id is 2, set 'declines_second_reading' to true or false, never null. Decide from the
           words of the amendment itself, not from its tone. The House of Representatives Guide to
           Procedures lists the standard forms:
             declines_second_reading = true
               - "the House declines to give the bill a second reading as it is of the opinion that ..."
               - "the bill be withdrawn and redrafted to provide for ..."
               - "the bill be withdrawn and a select committee be appointed to inquire into ..."
               - "the House is of the opinion that the bill should not be proceeded with until ..."
             declines_second_reading = false
               - "whilst not declining to give the bill a second reading, the House is of the opinion that ..."
               - "whilst not opposing the provisions of the bill, the House is of the opinion that ..."
               - "the House disapproves of the inequitable and disproportionate charges imposed by the bill ..."
           The two "whilst not ..." forms contain "declining to give the bill a second reading" inside a
           negation, and they are false, not true.

        8. FACTS A TEMPLATE NAMES:
           Some templates name one thing the motion concerns. For those, give references.facts.<name> as
           {"unit": "<ID>", "text": "<the words>"}: the ID of the unit where it appears, usually the motion or
           the chair's question, and the words exactly as they appear in that unit. The words are only used
           to find the place; what is printed is Hansard's own text, and a phrase not found in that unit is
           not printed. Leave a fact out when the transcript does not state it. Never give a URL, a party, or
           an electorate or title the transcript does not state; the program looks those up itself.
        #{fact_lines}

        9. DEBATE HEADINGS ARE NOT VOTES:
           A heading such as "Limitation of Debate" describes a stretch of business, not each division under
           it. Substantive amendment and bill votes are routinely held under such a heading. Never select
           Template 18 for a question that is not itself about limiting the time for debate.

        10. MISSING EVIDENCE:
           Debate is often adjourned and resumed, and a division can be put days after the motion was moved,
           so the transcript can lack what you need. List in interpretation.missing each kind of evidence you
           looked for and could not find: #{ExtractionPayload::MISSING_EVIDENCE.map { |key, what| "\"#{key}\" (#{what})" }.join(', ')}.
           An empty list means you found what the template needs. Do not report "mover_speech" just because
           the mover gave no explanation; report it when only a reference to their speech is here.
           An "EARLIER IN THIS DEBATE" section holds speeches from earlier in the same debate that moved
           something or put a question; use it to find a motion moved before the division was taken.
           A <context_warnings> block lists reasons the speeches here may not be the debate about this
           division. Check them against <speaker_question>, and report what is missing when they do not match.

        11. AUSTRALIAN PARLIAMENTARY PROCEDURE:
           - "Stand as printed": in the Senate, an amendment to omit a clause, item, section, Subdivision,
             Division, Part or Schedule is put as "That the [unit] stand as printed". A vote against it is
             what omits the unit. Use template_id 28 for these questions. "That the bill stand as printed" is
             not an omission: it is the final question in committee of the whole when no amendments were
             agreed to, and is not template 28.
           - Adjourning a debate is template 19. Only "That the House (or Senate) do now adjourn" is 26.

        Respond ONLY with a JSON object in this shape. No markdown fences, no commentary:
        {
          "interpretation": {
            "template_id": 1 to #{TemplateCatalogue::IDS.last},
            "declines_second_reading": true, false or null,
            "missing": []
          },
          "references": {
            "explanation": ["S3.4", "S3.5"],
            "motion": [],
            "facts": {}
          }
        }
      PROMPT
    end

    def catalogue_lines
      TemplateCatalogue.entries.map { |entry| format("   %<id>2d: %{prompt}", id: entry.id, prompt: entry.prompt) }
                       .join("\n")
    end

    def fact_lines
      TemplateCatalogue.entries.reject { |entry| entry.facts.empty? }.map do |entry|
        facts = entry.facts.map { |name, description| "'#{name}' is #{description}" }.join("; ")
        "   - Template #{entry.id} (#{entry.name}): #{facts}."
      end.join("\n")
    end
  end
end
