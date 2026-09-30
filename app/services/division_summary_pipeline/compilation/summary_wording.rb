# frozen_string_literal: true

module DivisionSummaryPipeline
  # The human-authored sentences a summary is built from, each chosen by what
  # ParliamentaryOutcome decided the division meant. Nothing here is generated: every string is
  # fixed wording, checked against the House Guide to Procedures and the Guides to Senate
  # procedure (KNOWN_ISSUES.md cites the passages), with only database facts and Hansard's own
  # words filled in.
  class SummaryWording
    SECTION_53_NOTE = "Section 53 of the Constitution stops the Senate amending a bill imposing taxation or " \
                      "appropriating money for the ordinary annual services of the government, so the Senate " \
                      "asks the House of Representatives to make the change instead. The House may make the " \
                      "requested amendment, decline to make it, or make it in a modified form."

    # Either side of the chair's own words saying a limitation of debate's time has expired
    # (EvidenceSections#limitation). Senate Guide No. 17: once the time expires the chair must
    # put the question then before the Senate, and any other questions necessary to conclude
    # proceedings on the bill; Template 18's explainer gives the House's form.
    LIMITATION_OF_DEBATE_LEAD = "This question was put under a limitation of debate, often called a 'guillotine'."
    LIMITATION_OF_DEBATE_EFFECT = "Once the time allotted for debate has expired, the chair puts the questions still " \
                                  "to be decided one after another, without further debate."

    attr_reader :outcome

    # The sentence before the chair's words saying why the question was put without debate: a
    # limitation of debate, or in the House a resolution agreed earlier, which is not a guillotine
    # and is not called one (House Guide p. 75; KI-52).
    def limitation_lead
      date = outcome.resolution_agreed_on
      return LIMITATION_OF_DEBATE_LEAD unless date

      "This question was put without further debate, under an arrangement the #{chamber} agreed on #{date}."
    end

    def limitation_effect
      outcome.resolution_agreed_on ? nil : LIMITATION_OF_DEBATE_EFFECT
    end

    delegate :facts, :template_id, to: :outcome
    delegate :chamber, :other_chamber, :senate?, to: :facts

    def initialize(outcome)
      @outcome = outcome
    end

    # Every template's vote sentence reads "voted for/against/on ...", which is why any spelling
    # of the result is reduced to these words here.
    def result_phrasing
      return "on" if outcome.tied?

      outcome.successful? ? "for" : "against"
    end

    def successful_text
      return "not decided, because fewer than a quorum of members voted" if outcome.want_of_quorum?
      return "not decided by the division figures, which were equal" if outcome.tied? && !senate?

      outcome.successful? ? "successful" : "unsuccessful"
    end

    # "a majority", "an overwhelming majority": the article is chosen from the value once
    # (KI-17), rather than patched up across the whole document afterwards.
    def amount
      raw = facts.amount.presence
      raw = "equally divided #{chamber}" if outcome.tied? && (raw.blank? || raw == "majority")
      (raw || "majority").sub(/\A[Aa]n?\s+/, "").strip
    end

    def amount_with_article
      amount.downcase.match?(/\A[aeiou]/) ? "an #{amount}" : "a #{amount}"
    end

    def rebellions_text
      divided_question_notice + party_votes_text
    end

    def party_votes_text
      text = if facts.free_vote
               "This was a conscience vote (free vote). #{senate? ? 'Senators' : 'Members'} were not bound by party " \
                 "whips, so no party rebellions are recorded.\n"
             else
               rebellions_line
             end
      text + result_notice + absolute_majority_notice
    end

    def amendment_effect_clause
      outcome.successful? ? "The text of the bill has been changed accordingly." : ""
    end

    # Template 28 ("That the [unit] stand as printed") is the one question whose result and
    # whose effect on the bill point opposite ways: carrying it keeps the unit, defeating it
    # omits the unit (Guides to Senate Procedure, No. 16). The vote direction stays true to the
    # question actually put, because that is what the counts are counts of; the consequence is
    # spelled out separately so the two cannot be read as contradicting each other.
    def stand_as_printed_effect_clause
      return "" unless template_id == 28

      if outcome.successful?
        "Because the question was that it stand as printed, agreeing to it kept that part of the bill unchanged " \
          "and defeated the amendment to omit it."
      else
        "Because the question was that it stand as printed, defeating the question is what omitted that part of " \
          "the bill. The amendment to omit it therefore succeeded, and the text of the bill has changed accordingly."
      end
    end

    # Which parts the question named, and whose amendments to omit them it decided, both in
    # Hansard's words: without them a draft never said which parts of the bill the vote kept
    # (KI-45). Ends with a space, as it sits before the effect clause.
    def stand_as_printed_parts_sentence
      return "" unless template_id == 28

      parts = outcome.stand_as_printed_parts
      by = outcome.circulation&.by
      named = "The question named \"#{parts}\"." if parts
      circulated = "The amendments to omit #{parts ? 'them' : 'it'} were circulated by #{by}." if by
      [named, circulated].compact.map { |sentence| "#{sentence} " }.join
    end

    # What carrying a reasoned amendment does is settled in neither chamber. The House guide
    # records the one time it happened (House Guide pp. 69-70, KI-9); the Senate guide lists what
    # such an amendment may do (Senate Guide No. 16) but not what carrying one does, so a Senate
    # summary says nothing rather than borrow the House's answer.
    def carried_amendment_note
      return "" if senate?

      " The standing orders do not say what happens when one is carried in the House. The House's Guide to " \
        "Procedures (2017) records it happening once, in 2016, when standing orders were then suspended so the bill " \
        "could be restored, and puts it no higher than that carriage \"would likely be regarded as preventing further " \
        "progress on the bill\"."
    end

    # Template 2's vote sentence, which says the opposite thing depending on whether the
    # amendment declined the bill a second reading (KI-11).
    def second_reading_amendment_sentence(mover_clause, bill_reference)
      plural = outcome.plural_amendments?
      noun = plural ? "second reading amendments" : "a second reading amendment"
      sentence = "At #{facts.time}, #{amount_with_article} voted #{result_phrasing} #{noun}#{mover_clause} to the " \
                 "#{bill_reference}, #{means_clause} #{successful_text}."
      if outcome.declines_second_reading
        "#{sentence} Because the #{plural ? 'amendments' : 'amendment'} sought to refuse the bill a second reading, " \
          "a vote for #{plural ? 'them' : 'it'} was in effect a vote against the bill proceeding."
      else
        "#{sentence} The text of the bill is unchanged either way."
      end
    end

    # Templates 3 and 4 name what was put, which under a limitation of debate is often a set of
    # circulated amendments decided in one question.
    def amendment_phrase
      outcome.plural_amendments? ? "amendments" : "an amendment"
    end

    def means_clause
      outcome.plural_amendments? ? "which means they were" : "which means it was"
    end

    # What a reading decided takes both halves: the template says which reading the chamber was
    # asked about, and the result says whether it agreed. Reading the stage alone is what let a
    # defeated third reading compile to "the bill has now passed" (KI-1).
    def second_reading_clause
      if outcome.successful?
        "This means the #{chamber} agreed with the main idea of the bill and can now consider it in greater detail."
      else
        "This means the #{chamber} did not agree to the bill in principle, so it goes no further at this stage."
      end
    end

    def passing_stage_clause
      outcome.passing_variant == :remaining_stages ? "through all its remaining stages" : "through its third reading"
    end

    # Template 6's sentence already ends "which means it was successful", so this starts afresh
    # rather than with a second "This means" (KI-48).
    def third_reading_clause
      return constitution_alteration_clause if outcome.constitution_bill?
      return "The bill did not pass the #{chamber}." unless outcome.successful?

      # Where a bill goes once it passes depends on where it started, which TVFY does not record
      # (KI-1): stated only when a supplied bill_originating_house settles it.
      passed = "The bill has now passed the #{chamber}."
      return passed unless supplied_chamber(facts[:bill_originating_house]) == chamber

      "#{passed} It started in the #{chamber}, so it now goes to the #{other_chamber}."
    end

    def closure_explainer
      case outcome.closure_variant
      when :business_of_the_day
        "*This motion ends a discussion on a matter of public importance. Such a discussion has no question " \
        "before the Chair, so there is nothing for the chamber to decide at the end of it, and this motion is " \
        "the only way to cut one short. If it is agreed to the discussion stops and the chamber moves on to the " \
        "next item of business.*"
      when :ballot
        "*During the election of a Speaker this is the motion used to end the debate so the ballot can be held. It " \
        "decides only that the ballot happens now.*"
      else
        "*This motion stops the debate and forces an immediate vote on whatever is being discussed. It decides only " \
        "that the talking ends. It does not decide the underlying question, which is put to a separate vote " \
        "straight afterwards. It cannot be moved for proceedings already covered by a time limit (a " \
        "'guillotine'), because the timetable has taken its place.*"
      end
    end

    # What the debate a closure ended was about, by the template the motion it cut short settles on
    # (ContextPacket#closed_template_id). %{bill} is "the [Bill](link)", or "the bill".
    CLOSED_DEBATES = {
      17 => "a motion to suspend standing orders",
      29 => "the second reading of %{bill}",
      2 => "a second reading amendment to %{bill}",
      6 => "the third reading of %{bill}",
      16 => "a matter of urgency",
      10 => "a censure motion"
    }.freeze

    # bill_reference is nil when the division has no bill: closures are moved on suspensions,
    # urgency motions and general business as often as on bills, and every one of those once read
    # "to end the debate on bill" (KI-46). Where Stage 1 found what the debate
    # was on, the sentence says so (KI-54).
    def closure_action_clause(bill_reference)
      case outcome.closure_variant
      when :business_of_the_day then "to call on the business of the day and end the discussion"
      when :ballot then "to end the debate and take the ballot immediately"
      else "to end the debate#{closed_debate_phrase(bill_reference)} and put the question immediately"
      end
    end

    def closed_debate_phrase(bill_reference)
      the_bill = bill_reference ? "the #{bill_reference}" : "the bill"
      closed = CLOSED_DEBATES[outcome.closed_template_id]
      return " on #{format(closed, bill: the_bill)}" if closed
      return " on #{the_bill}" if bill_reference

      ""
    end

    # The closure template points the reader at the division that put the underlying question
    # when a followup_link is supplied; resolving that link is not built yet
    # (ARCHITECTURE.md section 15).
    def followup_clause
      variant = outcome.closure_variant
      unless outcome.successful?
        return "The discussion continued." if variant == :business_of_the_day
        return "Debate on the election continued." if variant == :ballot

        return "The debate continued."
      end

      case variant
      when :business_of_the_day
        "There was no question before the Chair to decide, so the #{chamber} moved straight to the next item of business."
      when :ballot
        "The #{chamber} then proceeded to the ballot."
      else
        link = facts[:followup_link]
        link.present? ? "The #{chamber} then voted on the question itself, which you can read about [here](#{link})." : "The #{chamber} then voted on the question itself."
      end
    end

    # Template 17 quotes the suspension's own purpose in the standard form's own words, and says
    # nothing when the motion does not state one: a stock "to debate an urgent matter" was a guess
    # (KI-10). Quoted, because nearly every suspension is moved in the first person, and spliced into
    # the sentence unquoted "prevent me from moving a motion" read as They Vote For You speaking
    # (KI-26).
    def suspension_purpose_clause
      return "" unless template_id == 17

      purpose = outcome.suspension_purpose
      purpose ? " \"as would prevent #{purpose}\"" : ""
    end

    def suspension_effect_clause
      outcome.successful? ? "The usual rules were set aside so the matter could be dealt with immediately." : ""
    end

    def urgency_matter_clause
      matter = outcome.urgency_matter
      matter ? "declaring a matter of urgency: \"#{matter}\"" : "declaring a matter of urgency"
    end

    # What the rearrangement does, quoted after "to rearrange the business of the Senate": the
    # motion's own words when it is one short paragraph, otherwise the phrase the model pointed at,
    # otherwise nothing. Spliced in unquoted after "specifically that", whatever the model chose had
    # to be a grammatical clause, and drafts printed "specifically that That" and "specifically
    # that the substantive motion, minus 2(a) and (b)" (KI-26).
    def rearrangement_clause(description)
      text = outcome.rearrangement_terms.presence || description.to_s.strip.presence
      text ? " (\"#{text}\")" : ""
    end

    # House S.O. 94(d) (as at 23 July 2025) sets escalating periods rather than "the remainder of
    # the sitting", and only the second and third leave out the day of the suspension: the first is
    # "the 24 hour period from the time of suspension". The limits on petitions, notices and matters
    # of public importance are the House Guide's (2017) account of practice, not a standing order.
    # The Senate uses a different form of words again (KI-7). Senate S.O. 204 sets the Senate's
    # periods, but the edition checked here is from 2009 and the Guides to Senate procedure do not
    # state them, so this says where to look instead of asserting them.
    def suspension_period_sentence
      if senate?
        "The Senate names a senator under standing order 203 and sets the period of suspension under standing " \
          "order 204; the Senate's own guide does not state those periods, so they are not given here."
      else
        "A member suspended from the service of the House is excluded from the Chamber, all its galleries and any " \
          "room where the Federation Chamber is meeting, and while suspended cannot present petitions, give notices " \
          "or propose a matter of public importance, though they may still serve on a committee. The suspension runs " \
          "for 24 hours from the time of suspension on a first occasion, for the three consecutive sittings after the " \
          "day of the suspension on a second occasion in the same calendar year, and for the seven consecutive " \
          "sittings after that day on a third or later occasion."
      end
    end

    def suspension_form
      senate? ? "sitting" : "service"
    end

    def message_action_clause
      case outcome.message_form
      when :agree then "to agree to the amendments the #{other_chamber} made"
      when :disagree then "to disagree to the amendments the #{other_chamber} made"
      when :not_insist then "that the #{chamber} not insist on its own amendments"
      when :insist then "that the #{chamber} insist on its own amendments"
      when :request then "about the Senate's requests for amendments"
      else "concerning the amendments made"
      end
    end

    def message_effect_clause
      successful = outcome.successful?
      case outcome.message_form
      when :request then SECTION_53_NOTE
      when :not_insist then not_insist_effect_clause
      when :agree
        if successful
          "Agreeing to the motion accepted the #{other_chamber}'s changes to the bill."
        else
          "Defeating the motion means the #{other_chamber}'s changes were not accepted, so the bill goes back to it for further negotiation."
        end
      when :disagree
        if successful
          "Agreeing to the motion rejected the #{other_chamber}'s changes, and the bill goes back to it with the reasons for the disagreement."
        else
          "Defeating the motion means the #{other_chamber}'s changes were not rejected at this point."
        end
      when :insist
        if successful
          "Agreeing to the motion means the #{chamber} kept its own amendments, so the bill goes back to the #{other_chamber} with them."
        else
          "Defeating the motion means the #{chamber} did not insist on its own amendments, so the bill proceeds without them."
        end
      else
        ""
      end
    end

    def general_motion_effect_clause
      outcome.opinion_motion? ? " The motion records an opinion of the #{chamber} and has no legal effect." : ""
    end

    # House Guide pp. 15-16: a defeated adjournment returns the chamber to the business it was
    # part way through, which is the half a reader is least likely to guess.
    def adjournment_effect_clause
      return "" unless template_id == 26
      return "" if outcome.tied? && !senate?

      outcome.successful? ? "The #{chamber} adjourned." : "The #{chamber} returned to the business it was part way through."
    end

    def continuation_clause
      outcome.successful? ? "They were unable to continue speaking, and the debate went on without them." : "They were able to continue speaking."
    end

    def regulation_status_clause
      outcome.successful? ? "The regulation no longer has legal force." : "The regulation remains in force."
    end

    private

    def rebellions_line
      rebellions = facts.rebellions
      if rebellions.is_a?(String) && rebellions.strip.present?
        "#{rebellions.strip}\n"
      elsif rebellions.is_a?(Integer) && rebellions.positive?
        "#{rebellions} #{(senate? ? 'senator' : 'member').pluralize(rebellions)} voted against their party.\n"
      else
        "Nobody voted against their party on this occasion.\n"
      end
    end

    # Said first among the notices after the vote sentence, since it changes what the vote was on.
    def divided_question_notice
      parts = outcome.divided_parts
      return "" unless parts

      put = parts.match?(/\band\b|,/) ? "those parts were" : "that part was"
      "The question was divided, so this vote was on the motion without \"#{parts}\"; #{put} put to the #{chamber} " \
        "as a separate question.\n"
    end

    # The two chambers resolve an equally divided vote in opposite ways, so this is one of the
    # few places a summary has to know which chamber it is in. The Senate wording follows the
    # Guides to Senate Procedure ("the question is lost") rather than section 23's own "shall
    # pass in the negative", which a reader can easily take to mean it passed.
    def result_notice
      if outcome.want_of_quorum?
        "Notice: only #{facts.turnout} members voted, fewer than the quorum of #{outcome.quorum_threshold}. Under " \
          "House Standing Order 58 the House does not make a decision on a question when a division shows fewer " \
          "than a quorum voting.\n"
      elsif outcome.tied? && senate?
        "Because the votes were equally divided, the question was lost. The President of the Senate votes as an " \
          "ordinary senator and has no casting vote, so under Section 23 of the Constitution an equally divided " \
          "question fails.\n"
      elsif outcome.tied?
        "Because the votes were equally divided, the result was decided by the casting vote of the occupant of the " \
          "Chair. Under Section 40 of the Constitution the Speaker does not vote unless the numbers are equal, and " \
          "then has a casting vote. The division figures do not record which way that casting vote went, so this " \
          "one needs checking against the official record.\n"
      else
        ""
      end
    end

    # Said only where it changes what a reader should conclude (KI-5): the ayes cleared a simple
    # majority but not the absolute one.
    def absolute_majority_notice
      return "" unless outcome.absolute_majority_in_doubt?

      threshold = outcome.absolute_majority
      if outcome.absolute_majority_requirement == :always
        "Notice: this question needed an absolute majority, meaning at least #{threshold} of all the members of the " \
          "#{chamber} and not just of those voting. #{facts.aye_votes} voted for it. The recorded result and that " \
          "requirement do not agree, so this summary needs checking against the official record before it is relied on.\n"
      else
        # House S.O. 47 as at 23 July 2025 and House Guide pp. 2-3; Senate S.O. 209 and Senate Guide No. 5.
        lower = if senate?
                  "Moved on notice or under a contingent notice"
                else
                  "Moved on notice, by leave, or with the agreement of the Leader of the House and the Manager of " \
                    "Opposition Business"
                end
        "Notice: a motion to suspend standing orders moved without notice needs an absolute majority, meaning at " \
          "least #{threshold} of all the members of the #{chamber}. #{lower}, a majority of those voting is enough. " \
          "#{facts.aye_votes} voted for this one, so the result turns on which threshold applied, and the question " \
          "alone does not record which it was.\n"
      end
    end

    def supplied_chamber(value)
      text = value.to_s.downcase
      return "Senate" if text.include?("senate")
      return "House of Representatives" if text.match?(/representative|reps|\bhouse\b/)

      nil
    end

    # Section 128 requires a Constitution Alteration bill to pass each house by an absolute
    # majority. The House always rings the bells for a division at the third reading "even when
    # this question is carried on the voices" (House S.O. 173), and the Senate records the names
    # even if no division is called, so a division with no votes against is the rule working.
    def constitution_alteration_clause
      requirement = "Because this is a Constitution Alteration bill, Section 128 of the Constitution requires it to " \
                    "pass by an absolute majority, meaning a majority of all the members of the chamber and not just " \
                    "of those who voted."
      return "#{requirement} The bill did not pass this stage." unless outcome.successful?

      # Unconditional, unlike a suspension, so a result recorded as carried on fewer votes than it
      # needs is a contradiction the summary must not resolve in either direction (KI-5).
      if outcome.absolute_majority_met? == false
        return "#{requirement} Fewer members voted for the bill than that majority requires, so whether it passed " \
               "this stage does not follow from the division figures alone."
      end

      recording = if senate?
                    "The Senate records the names of senators voting on the third reading of such a bill even when no division is called, so that the constitutional majority is on the record."
                  else
                    "The House always rings the bells for a division at this stage, even when nobody opposes the bill, so that the constitutional majority is on the record."
                  end
      "The bill has now passed the #{chamber} and will go to the #{other_chamber}. #{requirement} #{recording}"
    end

    def not_insist_effect_clause
      if outcome.tied? && senate?
        "The votes were equally divided, so the question was lost. On this form of question that means the " \
          "amendments are not insisted on, because an equal vote shows they no longer command a majority, and the " \
          "bill proceeds without them. The chair of committees makes a statement explaining the result when this happens."
      elsif outcome.successful?
        "Agreeing to the motion means the #{chamber} dropped its own amendments, so the bill proceeds without them."
      else
        "This question was put as \"does not insist\", so defeating it is what insists on the amendments: they " \
          "stand, and the bill goes back to the #{other_chamber} with them."
      end
    end
  end
end
