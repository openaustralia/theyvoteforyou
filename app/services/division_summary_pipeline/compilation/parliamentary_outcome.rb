# frozen_string_literal: true

module DivisionSummaryPipeline
  # What a division decided, worked out from the database facts, the template and the words of
  # the motion and question as Hansard recorded them. This is where parliamentary meaning is
  # decided; SummaryWording only chooses the sentences that say it, and TemplateCompiler only
  # prints them, so the code that writes Markdown never decides what a vote meant.
  #
  # Several of these read the motion's own words, because one template covers questions that
  # mean different things (the message family, the three closures) and only the words tell them
  # apart. The words are always Stage 1's or a verified model reference's
  # (Evidence), never anything the model wrote, and the question stands in only where no motion
  # was recorded.
  class ParliamentaryOutcome
    # The House grew from 150 to 151 seats at the 2019 election, which moved the quorum (one
    # fifth of the House) from 30 to 31. Only used when the member records cannot say.
    HOUSE_OF_151_FROM = Date.new(2019, 7, 1)

    # More than half of all the members of the chamber. The House guide gives 76 for a House of
    # 150 and the Senate guide gives 39 of 76; a known member count supersedes them.
    HOUSE_ABSOLUTE_MAJORITY = 76
    SENATE_ABSOLUTE_MAJORITY = 39

    attr_reader :facts, :template_id, :motion_text, :question_text, :declines_second_reading, :circulation,
                :limitation_text, :closed_template_id

    # circulation: the Circulation when the chair put amendments nobody moved, as Stage 1 found it.
    # limitation_text: the chair's sentence saying the question was put under a limitation of
    # debate, or under a resolution agreed earlier.
    # closed_template_id: for a closure, the template of the motion it cut short (ContextPacket).
    def initialize(facts:, template_id:, motion_text: nil, question_text: nil, declines_second_reading: nil,
                   circulation: nil, limitation_text: nil, closed_template_id: nil)
      @closed_template_id = closed_template_id
      @facts = facts
      @template_id = template_id
      @motion_text = motion_text.to_s
      @question_text = question_text.to_s
      @declines_second_reading = declines_second_reading
      @circulation = circulation
      @limitation_text = limitation_text.to_s
    end

    # What a divided question left out, in the chair's words ("2(a) and (b)"), or nil: the vote was
    # on the motion without those parts, which a reader looking at the whole motion printed below
    # would otherwise take to be part of it (KI-53).
    def divided_parts
      ChairStatement.divided_parts(question_text)
    end

    # The date of the resolution under which the Speaker put the question immediately ("12 August
    # 2026"), in the Speaker's own words, or nil when the question was not put that way. Such a
    # resolution is a programming motion moved by suspending standing orders, which the House
    # Guide (p. 75) says achieves an effect similar to the guillotine, but is not one.
    def resolution_agreed_on
      limitation_text[/\bresolution\s+agreed\s+to\s+on\s+(\d{1,2}\s+[A-Z][a-z]+\s+\d{4})\b/, 1]
    end

    # Whether the question put more than one amendment at once, as the chair does with circulated
    # amendments.
    def plural_amendments?
      circulation&.plural.present?
    end

    # The parts of the bill a "stand as printed" question names, in the chair's words: "part 8 of
    # schedule 1; items 29, 30 and 32 in schedule 1" (Senate Guide No. 16). The last such question
    # in the chair's words, which is the one the division decided.
    STAND_AS_PRINTED = /#{ChairStatement::QUESTION.source}\s+(.+?)\s+stand\s+as\s+printed\b/im

    def stand_as_printed_parts
      parts = question_text.scan(STAND_AS_PRINTED).last&.first
      parts&.gsub(/\s+/, " ")&.strip.presence
    end

    # The words that say what was moved: the motion itself where it was recorded, the question
    # where it was not.
    def operative_text
      motion_text.presence || question_text
    end

    def successful?
      facts.agreed?
    end

    def member_count
      return @member_count if defined?(@member_count)

      @member_count = facts.member_count
    end

    # The quorum is "at least one fifth of the whole number of the Members of the House" (House
    # of Representatives (Quorum) Act 1989), so it tracks the size of the House (KI-8). House
    # S.O. 58 is what makes it worth reporting: if a division shows fewer than a quorum voting,
    # the House has not made a decision. nil when neither the member count nor the date is known,
    # because getting this wrong means telling a reader a decision parliament did make was never
    # made. There is no Senate equivalent on purpose: the Guides to Senate Procedure set out no
    # rule voiding a Senate division for want of a quorum, and a citation we cannot check is not
    # one to publish.
    def quorum_threshold
      return nil if facts.senate?
      return (member_count / 5.0).ceil if member_count

      date = Date.parse(facts.date.to_s)
      date >= HOUSE_OF_151_FROM ? 31 : 30
    rescue ArgumentError, TypeError
      nil
    end

    def want_of_quorum?
      threshold = quorum_threshold
      threshold.present? && facts.turnout.positive? && facts.turnout < threshold
    end

    # An equally divided division had no majority either way. The Senate loses the question
    # (Constitution s 23); in the House the occupant of the Chair has a casting vote (s 40) that
    # the counts do not record (KI-18).
    def tied?
      facts.tied || (facts.turnout.positive? && facts.aye_votes == facts.no_votes && !want_of_quorum?)
    end

    def absolute_majority
      return (member_count / 2) + 1 if member_count

      facts.senate? ? SENATE_ABSOLUTE_MAJORITY : HOUSE_ABSOLUTE_MAJORITY
    end

    # nil means "no figures to judge it by", which is not the same as "not met".
    def absolute_majority_met?
      facts.aye_votes >= absolute_majority if facts.aye_votes.positive?
    end

    # Which questions need an absolute majority rather than a majority of those voting (KI-5).
    #
    # :always - section 128 of the Constitution on the third reading of a Constitution
    #   Alteration bill (House S.O. 173, Guide p. 77; Senate Guide No. 3), and rescinding an
    #   order of the Senate (Senate S.O. 87).
    # :conditional - a suspension of standing orders, where it depends on how the motion was
    #   moved: without notice it needs the absolute majority (House S.O. 47(c), Senate
    #   S.O. 209), but on notice or under a contingent notice a simple majority is enough, as it is
    #   in the House when moved by leave (House Guide pp. 2-3) or, without notice, when the Leader
    #   of the House and the Manager of Opposition Business agree (S.O. 47(c)(ii) as at 23 July
    #   2025). Senate Guide No. 5 says contingent notices are used for most suspensions precisely
    #   to avoid the higher bar. The question alone does not say which applied.
    def absolute_majority_requirement
      return :always if template_id == 6 && constitution_bill?
      return :always if facts.senate? && operative_text.match?(/\brescind(?:ed|ing)?\b/i)
      return :conditional if template_id == 17

      nil
    end

    # The ayes cleared a simple majority but not the absolute one, so the recorded result and
    # the requirement disagree, and the summary says so rather than picking a side.
    def absolute_majority_in_doubt?
      absolute_majority_requirement.present? && successful? && facts.aye_votes.positive? &&
        facts.aye_votes < absolute_majority
    end

    def constitution_bill?
      [facts.bill_name, facts.name].compact.any? { |text| text.to_s.match?(/constitution\s+alteration/i) }
    end

    # Template 7 covers the whole message family, and the forms in it do not all mean the same
    # thing, or even point the same way: "does not insist" is carried to drop this chamber's own
    # amendments and defeated to keep them (Senate Guide No. 18; KI-2). Order matters: "does not
    # insist on its amendments to which the House has disagreed" contains "disagreed", and
    # "disagreed" contains "agree".
    def message_form
      text = operative_text.downcase
      return :not_insist if text.match?(/\b(?:does not|do not|not)\s+insist\b/)
      return :insist if text.match?(/\binsist/)
      return :request if text.match?(/\brequest/)
      return :disagree if text.match?(/\bdisagree/)
      return :agree if text.match?(/\bagree/)

      :unknown
    end

    # Three different questions arrive as Template 22, and only their words tell them apart
    # (KI-3): the ordinary closure (House S.O. 81); "That the business of the day be called on",
    # which exists only to curtail a matter of public importance discussion, "because there is no
    # question before the Chair during an MPI" (House Guide pp. 40-41, S.O. 46(e)); and "That the
    # ballot be taken now" during the election of a Speaker (House S.O. 11(h), Guide p. 41).
    def closure_variant
      text = "#{motion_text} #{question_text}"
      return :business_of_the_day if text.match?(/business of the day be called on/i)
      return :ballot if text.match?(/ballot be taken now/i)

      :closure
    end

    # Template 6 covers two questions (ProceduralRouter#third_reading): the third reading itself,
    # and the Senate's "that the remaining stages of the bill be agreed to, and the bill be now
    # passed", which takes every stage still outstanding in one vote. Only the words tell them
    # apart, and a summary of the second that says "third reading" names only one of its stages.
    def passing_variant
      "#{motion_text} #{question_text}".match?(/remaining stages/i) ? :remaining_stages : :third_reading
    end

    # A suspension motion states its own purpose, in the words after "as would prevent" (House
    # Guide p. 2; KI-10). The purpose runs to the end of its clause: a semicolon, a colon, a
    # paragraph break, or a full stop followed by a new sentence or the end. A plain full stop is
    # not enough, since purposes cite "notice of motion No. 3".
    SUSPENSION_PURPOSE = /as\s+would\s+prevent\s+(.+?)(?=[;:]|\n\s*\n|\.(?:\s+[A-Z]|\s*\z)|\z)/m

    def suspension_purpose
      match = operative_text.match(SUSPENSION_PURPOSE)
      match && match[1].to_s.gsub(/\s+/, " ").strip.sub(/[,-]\z/, "").presence
    end

    # Template 16 names the matter the motion declares urgent in the motion's own words, which
    # follow "is a matter of urgency:" (Senate S.O. 75).
    URGENCY_MATTER = /matter\s+of\s+urgency\s*[:-]\s*(.+)\z/im

    def urgency_matter
      match = operative_text.match(URGENCY_MATTER)
      match && match[1].gsub(/\s+/, " ").strip.sub(/\.\z/, "").presence
    end

    # A rearrangement of business stated in one short paragraph ("That the debate be adjourned."),
    # which says what the motion does without any need to ask the model (ADR 0005's first tier).
    # A longer motion has no one phrase for it, and is printed whole under Motion Text.
    REARRANGEMENT_MAXIMUM = 250

    def rearrangement_terms
      text = motion_text.strip
      text if text.match?(/\AThat\b/i) && text.exclude?("\n") && text.size <= REARRANGEMENT_MAXIMUM
    end

    # Template 15 is the fallback, so its sentence is printed over every question the router
    # could not place. It says the motion records an opinion and has no legal effect only where
    # the motion's own words are declaratory (KI-4).
    OPINION_MOTION_PATTERN = /
      \bis[ ]of[ ]the[ ]opinion\b | \bin[ ]the[ ]opinion[ ]of[ ]the\b |
      \b(?:house|senate|committee)[ ]+
      (?:notes|condemns|calls[ ]on|calls[ ]upon|believes|recognises|
      acknowledges|expresses|welcomes|deplores|regrets|affirms|declares)\b
    /xi

    def opinion_motion?
      template_id == 15 && operative_text.match?(OPINION_MOTION_PATTERN)
    end
  end
end
