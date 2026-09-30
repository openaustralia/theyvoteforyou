# frozen_string_literal: true

module DivisionSummaryPipeline
  # Stage 2: classifies a division from the Speaker's Question alone, before any LLM runs, and
  # returns a RoutingDecision.
  #
  # What a division decided is fixed by the one sentence the chair puts to the chamber ("The
  # question is that..."), not by the Hansard heading above it or the subject being argued
  # about. Anchoring here is what defeats the heading traps below. Chamber, heading and
  # surrounding debate only narrow cases the question leaves genuinely open.
  #
  # The router does not try to understand procedure exhaustively. It catches the few cases that
  # are identifiable from structure alone and sets guardrails around the rest, and everything
  # genuinely ambiguous belongs to the extractor inside a fence, not to more rules here
  # (ARCHITECTURE.md, constraint 3). Its rules are of three kinds, one for each mode of
  # RoutingDecision:
  #
  # - Signatures: a form of words that settles the template on its own ("the question be now
  #   put", "do now adjourn", "take note of"). Built with `settle`.
  # - Guardrails: evidence of what cannot safely be inferred. A "Limitation of Debate" heading
  #   says nothing about what a vote decided, only that Template 18 must not be read into it,
  #   and a bill stage narrows the choice to a shortlist. Built with `fence`.
  # - The fallback, when nothing matched: a default the extractor may depart from
  #   (RoutingDecision.default).
  #
  # These live in code rather than in the prompt because they are stable and knowable, and
  # because a model asked to classify freely handles the easy cases and fails the traps.
  class ProceduralRouter
    # Tried in order, and the first rule to return a decision wins, so the order is part of the
    # logic. That is also why the kinds are not simply listed one after the other: a few
    # signatures have to sit below a guardrail they must not overtake, and each says so where it
    # is defined below.
    RULES = [
      # Signatures of a procedure. Each decides only its own procedure and nothing about the
      # underlying question, which is why they come before any rule about a subject: a
      # suspension question that mentions a censure is a vote on suspending the standing
      # orders, and the censure, if it follows, is a separate division that arrives on its own.
      :suspension_of_standing_orders,
      :closure_of_debate,
      :member_heard_in_the_senate, # a guardrail, kept beside the signature it qualifies
      :member_no_longer_heard,
      :suspension_of_member,
      :dissent_from_ruling,
      :adjournment_of_chamber,
      :take_note,
      :first_reading,

      # Guardrail: an amendment read out in a second reading debate, before any rule that reads
      # a subject into its words.
      :reasoned_amendment_form,

      :withdrawal_of_business,
      :parliamentary_zone_works,
      :disallowance_motion,
      :production_of_documents,
      :censure_motion,
      :estimates_committees,
      :select_committee,
      :selection_of_bills,
      :house_selection_committee,
      :matter_of_urgency,
      :rearrangement_of_business,
      :federation_chamber_report,
      :consideration_of_message,

      # Guardrail: a "Limitation of Debate" heading, then the only way into Template 18.
      :amendment_under_guillotine_heading,
      :guillotine_procedure,

      # Guardrails: bill stages, narrowed as far as the wording honestly allows.
      :third_reading,
      :second_reading_amendment,
      :second_reading,
      :stand_as_printed,
      :amendment_stage,
      :committee_referral
    ].freeze

    FALLBACK = "GENERAL_MOTION_FALLBACK"

    # An amendment's own forms, as the question reads them out with punctuation dropped: "Omit all
    # words after "That", substitute ...", "That all words after "That" be omitted with a view to
    # substituting ...", "At the end of the motion, add ...", and the House's older "That the words
    # proposed to be omitted stand part of the question".
    AMENDMENT_FORMS = ["omit all words after", "all words after that be omitted", "leave out all words after",
                       "at the end of the motion add", "words proposed to be omitted"].freeze

    # Openings that settle what a motion does however the rest of it reads: a suspension of
    # standing orders, a referral to a committee, an order for the production of documents and
    # the establishment of a select committee, as the Senate's standard forms word them.
    FIXED_MOTION_OPENINGS = [
      /\Athat so much of the standing/,
      /\Athat the following matters? be referred/,
      /\Athat there be laid on the table/,
      /\Athat a select committee/
    ].freeze

    # A bill's short title, found before the question is lowercased: a capitalised word, then
    # more of them, the short words titles keep in lower case and any parenthesised part, ending
    # in "Bill" and an optional "(No. 2)" and year, as in "Treasury Laws Amendment (Tax Reform
    # No. 1) Bill 2026". A bill that amends an Act is commonly titled "... Amendment Bill", which
    # says nothing about whether the question is on an amendment, so amendment wording is looked
    # for only outside titles (KNOWN_ISSUES.md, KI-29). A title is replaced rather than deleted
    # so the words either side of it stay apart.
    TITLE_WORD = /(?:[A-Z0-9][\w'.\u{2013}\u{2014}\u{2019}-]*|(?:a|an|and|as|at|by|for|from|in|into|of|on|or|the|to|with)\b)/
    TITLE_PART = /(?:#{TITLE_WORD}|\(#{TITLE_WORD}(?:,?\s+#{TITLE_WORD})*\))/
    BILL_TITLE = /
      \b[A-Z][\w'.\u{2013}\u{2014}\u{2019}-]*
      (?:,?\s+#{TITLE_PART})*?                # as few words as reach "Bill"
      \s+Bill\b
      (?:\s+\(No\.?\s*\d+\))?
      (?:\s+\d{4}(?:[-\u{2013}]\d{2,4})?)?    # a year, or a financial year
    /x

    # Ends the reason of an open route that forbids Template 18 because of the heading.
    HEADING_LOCKOUT_NOTE = " Heading was 'Limitation of Debate', so Template 18 is locked out."

    # motion_text is the first paragraph of the motion as moved (ContextBuilder, via
    # MoverFinder), used only when the question itself matched no rule. The chair often puts a
    # question by reference - "the motion moved by the member for Exampleton be agreed to",
    # "business of the Senate No. 3 ... as amended be agreed to" - and a reference carries none
    # of the words the rules look for, so it fell to the fallback even when the motion was a
    # suspension of standing orders or a committee referral. The question still wins whenever it
    # says enough on its own, since it is what the chamber actually decided, and only the
    # operative first paragraph is read so the clauses of a long motion cannot trip an unrelated
    # rule.
    #
    # Even a first paragraph can mislead: a motion amending a committee's resolution of
    # appointment names the committee without creating one. So a route taken from the motion is
    # only binding when the motion opens in one of the fixed forms above, and is otherwise a
    # default the extractor may depart from, like the fallback it replaced.
    def self.route(speaker_question:, chamber: "", debate_heading: "", hansard_snippet: "", motion_text: "")
      decision = new(speaker_question, chamber, debate_heading, hansard_snippet).decision
      return decision unless decision.rule_name == FALLBACK && motion_text.to_s.strip.present?

      from_motion = new(motion_text, chamber, debate_heading, hansard_snippet).decision
      return decision if from_motion.rule_name == FALLBACK

      reason = "The question referred to the motion without stating it, so it was routed on the " \
               "motion as moved. #{from_motion.reason}"
      return from_motion.with(diagnostic: from_motion.diagnostic.with(reason: reason)) if fixed_opening?(motion_text)

      RoutingDecision.default(from_motion.allowed_templates,
                              forbidden: from_motion.forbidden_templates, rule_name: from_motion.rule_name, reason: reason)
    end

    # A leading paragraph number ("(1) That ...") is not part of the opening.
    def self.fixed_opening?(motion_text)
      opening = motion_text.to_s.strip.downcase.sub(/\A\(\w+\)\s*/, "")
      FIXED_MOTION_OPENINGS.any? { |pattern| opening.match?(pattern) }
    end

    private_class_method :new

    def initialize(question, chamber, heading, context)
      question = question.to_s.strip
      chamber = chamber.to_s.strip.downcase
      @text = plain(question)
      @text_outside_titles = plain(question.gsub(BILL_TITLE, "bill"))
      @heading = heading.to_s.strip.downcase
      @context = context.to_s.strip.downcase
      @senate = chamber.include?("senate")
      @house = chamber.include?("representative") || chamber.include?("reps")
    end

    def decision
      RULES.each do |rule|
        matched = send(rule)
        return matched if matched
      end
      general_motion_fallback
    end

    private

    attr_reader :text, :heading, :context

    # ---------------------------------------------------------------------------------------
    # Signatures of a procedure
    # ---------------------------------------------------------------------------------------

    # Template 17: suspension of standing orders (the chamber's own rulebook). Decides only that
    # the rules are set aside, not the merits of whatever is then moved under them.
    #
    # First in the whole router, and it has to be. A suspension question recites the motion it
    # would clear the way for ("That so much of the standing orders be suspended as would
    # prevent ...", House Guide p. 2), so it contains the trigger words of whichever rule covers
    # that motion, including the closure rule next, since suspensions are routinely moved to let
    # a question be put forthwith. Any rule above this one reports the suspension division as the
    # thing it merely enabled (KNOWN_ISSUES.md, KI-16).
    def suspension_of_standing_orders
      return unless says?("standing orders be suspended", "standing and sessional orders be suspended",
                          "suspend standing orders", "so much of the standing")

      settle(17, "SUSPENSION_OF_STANDING_ORDERS", "Question moves to suspend standing or sessional orders.")
    end

    # Template 22: closure of debate. Decides only that debate ends now, never the matter under
    # debate, which is usually put in a separate division moments later. Also covers calling on
    # the business of the day to terminate an MPI (House S.O. 46(e)), and the "That the ballot
    # be taken now" form used to closure debate during the election of a Speaker (House
    # S.O. 11(h), Guide p. 41).
    def closure_of_debate
      return unless says?("question be now put", "question be put", "now put", "ballot be taken now",
                          "business of the day be called on")

      reason = if says?("business of the day")
                 "Question calls on the business of the day to terminate discussion."
               elsif says?("ballot be taken now")
                 "Question closures debate on the election of the Speaker so the ballot is taken."
               else
                 "Question explicitly moves that the question be now put."
               end
      settle(22, "CLOSURE_OF_DEBATE", reason)
    end

    # Template 23: member be no longer heard (or heard now, or further heard). This closure-like
    # gag exists only in the House of Representatives, so a match inside the Senate means the
    # chamber metadata or the question is wrong somewhere. Fence it for the extractor rather than
    # asserting it, and say why in the reason.
    def member_heard_in_the_senate
      return unless senate? && member_heard?

      fence([23], "MEMBER_NO_LONGER_HEARD_CHAMBER_CONFLICT",
            "Question concerns whether the member be heard, but this motion is a House of Representatives " \
            "procedure and this division is in the Senate. Verify the chamber before using Template 23.")
    end

    def member_no_longer_heard
      return unless member_heard?

      settle(23, "MEMBER_NO_LONGER_HEARD", "Question explicitly asks whether the member be heard or no longer heard.")
    end

    # Template 24: disciplinary naming and suspension of a member (House S.O. 94, Senate S.O. 203).
    def suspension_of_member
      return unless says?("suspended from the service", "suspended from the sitting")

      settle(24, "SUSPENSION_OF_MEMBER", "Question is for the disciplinary suspension of a member.")
    end

    # Template 25: dissent from a ruling of the Chair. Objection to a ruling must be taken at once
    # by a motion of dissent submitted in writing (House S.O. 87). The Senate has the same device;
    # the Guides to Senate Procedure don't give its standing order number, so none is cited here.
    def dissent_from_ruling
      return unless says?("ruling be dissented from", "dissent from the ruling", "dissent from the chair") ||
                    (says?("dissent") && says?("ruling"))

      settle(25, "DISSENT_FROM_RULING", "Question dissents from a ruling of the Chair.")
    end

    # Template 26: adjournment of the chamber. In the House the Speaker proposes "That the House do
    # now adjourn" at the time set for the adjournment (House S.O. 29, S.O. 31); the Senate has the
    # equivalent in its routine of business.
    def adjournment_of_chamber
      return unless says?("do now adjourn", "house do now adjourn", "senate do now adjourn")

      settle(26, "ADJOURNMENT_OF_CHAMBER", "Question is that the chamber do now adjourn.")
    end

    # Template 27: taking note of documents, committee reports, ministerial statements or answers
    # (House S.O. 202(a); Senate motions to take note of answers are debated under Senate S.O. 72(4)).
    def take_note
      return unless says?("take note of")

      settle(27, "TAKE_NOTE", "Question is to take note of a document, report, explanation or answer.")
    end

    # Template 1: first reading, the formal introduction of a bill. Carries no view on the bill's
    # merits, which is exactly what a reader is liable to assume it does.
    def first_reading
      return unless says?("read a first time", "first reading")

      settle(1, "FIRST_READING", "Question is for the bill to be read a first time.")
    end

    # Template 2, when the question reads out an amendment to the second reading. Its words name
    # what carrying it would lead to, and the subject rules below would settle on that: the House
    # guide's own reasoned amendment "the bill be withdrawn and a select committee be appointed to
    # inquire into ..." (pp. 68-69) as a select committee, and an amendment on the main
    # appropriation bill cast, by convention, as a censure of the Budget (pp. 81-82; KI-13) as a
    # censure. Both are votes on the amendment (KI-49). Only in a second
    # reading debate: the same forms amend ordinary motions too, which this router does not
    # settle.
    def reasoned_amendment_form
      return unless says?(*AMENDMENT_FORMS) && (second_reading? || heading.include?("second reading"))

      settle(2, "SECOND_READING_AMENDMENT_FORM",
             "Question reads out an amendment to the second reading, whatever subject its words name.")
    end

    # Template 20: withdrawal of business, removing an item from the Notice Paper (the chamber's
    # list of scheduled business) so it is not dealt with.
    #
    # "be withdrawn" also appears inside second reading amendments, because two of the standard
    # reasoned-amendment forms are "the bill be withdrawn and redrafted to provide for ..." and
    # "the bill be withdrawn and a select committee be appointed to inquire into ..." (House Guide
    # to Procedures pp. 68-69). Those are votes on an amendment to the second reading motion, so a
    # question that also names a bill stage or an amendment is left to the stage rules below.
    def withdrawal_of_business
      return if names_amendment? ||
                says?("read a second time", "second reading", "read a third time", "third reading", "words after")
      return unless says?("withdrawal of", "be withdrawn", "withdraw notice")

      settle(20, "WITHDRAWAL_OF_BUSINESS", "Question concerns withdrawing business or notices from the notice paper.")
    end

    # Template 21: Parliamentary Zone works, which the Parliament Act 1974 requires both houses to
    # approve by resolution.
    def parliamentary_zone_works
      return unless says?("parliamentary zone", "parliament act 1974")

      settle(21, "PARLIAMENTARY_ZONE_WORKS", "Question approves capital works within the Parliamentary Zone.")
    end

    # Template 9: disallowance. Regulations are law the government makes under powers an Act gives
    # it, without a fresh vote; disallowing one strips its legal force.
    def disallowance_motion
      return unless says?("disallow", "disallowance")

      settle(9, "DISALLOWANCE_MOTION", "Question explicitly moves to disallow a delegated legislative instrument.")
    end

    # Template 8: production of documents, the chamber ordering the government to hand over papers
    # it holds. These votes are about access to the documents, never about their subject, so a
    # missed match misroutes badly, and the wording varies: "papers" as well as "documents", "laid
    # upon" as well as "laid on the table". "Laid on the table" is enough on its own, since the
    # Senate's usual order reads "That there be laid on the table by the Minister ..., by no later
    # than ...:" and then lists what is wanted ("a copy of the report entitled ...", "all
    # ministerial submissions ..."), often without ever saying "documents" or "papers".
    def production_of_documents
      return unless says?("production of documents", "production of papers", "order for the production",
                          "produce documents", "laid on the table", "laid upon the table")

      settle(8, "PRODUCTION_OF_DOCUMENTS", "Question orders the government to produce documents or papers.")
    end

    # Template 10: censure, a formal expression of disapproval of a minister or member carrying no
    # legal effect. Motions of no confidence in a minister or member (often worded "want of
    # confidence") are the same class of vote. One moved under a suspension of standing orders is
    # still caught by the suspension rule first, by design.
    def censure_motion
      return unless says?("censure", "reprimand", "no confidence", "want of confidence")

      settle(10, "CENSURE_MOTION",
             "Question expresses censure or reprimand of a Minister or Member, or want of confidence in them.")
    end

    # Template 11: estimates committees, which question officials about planned department
    # spending. These votes organise that scrutiny; they do not decide the spending.
    def estimates_committees
      return unless says?("estimates") && says?("committee", "budget")

      settle(11, "ESTIMATES_COMMITTEES",
             "Question concerns referring or managing Budget considerations by Estimates committees.")
    end

    # Template 12: establishing a select committee, appointed to inquire into one subject and
    # disband once it reports. Distinct from a referral to a standing committee (13). Amending an
    # existing committee's "resolution of appointment" (its membership, say) names a select
    # committee and the word "appointment" without establishing anything.
    def select_committee
      return unless says?("select committee") && !says?("resolution of appointment") &&
                    says?("appoint", "establish", "inquire")

      settle(12, "SELECT_COMMITTEE", "Question establishes or appoints a Select Committee.")
    end

    # Template 14: the Selection of Bills Committee, the Senate committee that recommends which
    # bills other committees should examine before the Senate votes on them.
    def selection_of_bills
      return unless says?("selection of bills")

      settle(14, "SELECTION_OF_BILLS", "Question adopts a report of the Selection of Bills Committee.")
    end

    def house_selection_committee
      return unless says?("selection committee") && house?

      settle(19, "REARRANGEMENT_OF_BUSINESS",
             "Question adopts determinations of the House Selection Committee rearranging business.")
    end

    # Template 16: matter of urgency, the Senate's device for setting aside time to debate an issue
    # immediately. Decides that the debate happens, not the issue.
    def matter_of_urgency
      return unless says?("matter of urgency", "urgency motion")

      settle(16, "MATTER_OF_URGENCY", "Question declares an issue a Matter of Urgency (Senate).")
    end

    # Template 19: rearrangement of business. Also covers adjourning or postponing debate on a bill
    # or motion ("that the debate be adjourned", "the second reading be made an order of the day
    # for the next sitting"), and setting when something will be considered ("that the amendments
    # be considered at the next sitting" or "... considered immediately", the House's usual answers
    # to a Senate message). Those questions often name a bill stage or the amendments, so they must
    # be caught here, before the second reading and amendment rules fence them as though the bill
    # or the amendments themselves were being decided.
    def rearrangement_of_business
      return unless says?("rearrangement of business", "postpone", "order of the day be postponed",
                          "order of the day for the next", "debate be adjourned", "debate be now adjourned",
                          "adjourn the debate", "business of the senate be rearranged") ||
                    text.match?(/\bconsidered (?:at the next sitting|at a later hour|later this day|immediately)\b/)

      settle(19, "REARRANGEMENT_OF_BUSINESS", "Question rearranges or postpones parliamentary orders of business.")
    end

    # Template 5: a report from the Federation Chamber, or resolution of an unresolved question
    # (House S.O. 188).
    def federation_chamber_report
      return unless (says?("federation chamber") && says?("report", "agreed to")) ||
                    says?("unresolved question") || heading.include?("unresolved question")

      settle(5, "FEDERATION_CHAMBER_REPORT",
             "Question formally agrees to a report or resolves an unresolved question from the Federation Chamber.")
    end

    # Template 7: consideration of a message. A bill must pass both houses in identical words, so a
    # house that amends one sends the other a "message" to accept, reject, insist or request. Under
    # a message heading the House puts the other chamber's amendments without naming where they
    # came from.
    def consideration_of_message
      return unless says?("amendments made by the senate", "amendments made by the house", "senate message",
                          "house message", "consideration of senate amendments", "insist on its amendment",
                          "insists on its amendment", "does not insist", "disagree to the amendment",
                          "disagreed to and an amendment", "requested amendment", "requests be made",
                          "press its request") ||
                    (says?("disagreed to") && names_amendment?) ||
                    (heading.include?("message") && text.match?(/\bamendments? be (?:dis)?agreed to\b/))

      settle(7, "CONSIDERATION_OF_MESSAGE",
             "Question resolves amendments, messages, disagreements, or requests between the chambers.")
    end

    # ---------------------------------------------------------------------------------------
    # Guardrail: the "Limitation of Debate" heading
    #
    # The misclassification this whole stage exists to prevent. A "guillotine" caps the time
    # left for debate, and a "Limitation of Debate" heading then covers every division that
    # follows while it runs, substantive amendment and bill votes included. Reported as
    # time-limit procedure, those votes tell a reader the opposite of what their representative
    # actually decided.
    #
    # The heading alone therefore never identifies a guillotine motion: only a question that is
    # itself about limiting the time for debate does. Wherever routing stays open below it,
    # Template 18 is forbidden so the extractor cannot land on it from the heading alone.
    # ---------------------------------------------------------------------------------------

    # A guillotine heading over an amendment question: a substantive vote on the bill. The
    # extractor sees the same misleading heading, so Template 18 is forbidden outright rather than
    # merely left off the shortlist. A "stand as printed" question is already unambiguous about its
    # stage and its inversion, so the heading only has to be stopped from overriding it.
    def amendment_under_guillotine_heading
      return unless guillotine_heading? && substantive_amendment?

      fence(unit_stands_as_printed? ? [28] : amendment_stages, "GUILLOTINE_TRAP_AVOIDED",
            "Heading was 'Limitation of Debate', but the question is on an amendment. Template 18 locked out.",
            forbidden: [18])
    end

    # Template 18 is only ever reached this way, from a question about the time limit itself, never
    # from the heading a division happens to sit under.
    #
    # The House guillotine is two questions, not one (House S.O.s 82-84, Guide pp. 74-75): a
    # Minister declares the bill urgent, "That the bill be considered urgent" is put immediately
    # with no debate or amendment, and only then may a motion allotting time be moved. Both are
    # about how long the chamber spends on the business rather than about the business, so both
    # belong here; without the first form they fell through to the fallback and were described as
    # opinion-only motions (KNOWN_ISSUES.md, KI-4). "Matter of urgency" is a different thing
    # entirely, matched by its own rule before this one is reached.
    def guillotine_procedure
      urgent = says?("be considered urgent", "be considered an urgent bill", "declaration of urgency")
      return unless urgent || says?("time allotted", "allotment of time", "limitation of debate", "limitations of debate") ||
                    (says?("guillotine") && !substantive_amendment?)

      reason = if urgent
                 "Question declares the bill urgent, the first of the two questions that impose a House time limit."
               else
                 "Question is the limitation of debate (time allocation) itself."
               end
      settle(18, "GUILLOTINE_PROCEDURE", reason)
    end

    # ---------------------------------------------------------------------------------------
    # Guardrails: bill stages
    #
    # What remains are the bill stages, where one form of words can mean two different votes. A
    # bill is read three times in each chamber: the first reading introduces it, the second
    # reading settles its main idea, the third passes it out of the chamber. These rules narrow
    # as far as the wording honestly allows and fence the rest; where the wording settles the
    # stage, the rule is a signature placed here so it stays below the guillotine guardrail.
    # ---------------------------------------------------------------------------------------

    # Template 6: the third reading, the bill's final vote in this chamber.
    #
    # The Senate can also put every stage still outstanding as one question, "that the remaining
    # stages of the bill be agreed to, and the bill be now passed", as the chair does when a
    # guillotine's time runs out and must put "any other questions necessary to conclude
    # proceedings on the bill" (Senate Guide No. 17, Debating legislation under time limits). It
    # is the same final vote, so it is settled here too. Unmatched, it fell to the general motion
    # fallback, and a draft built on that never said the bill had passed.
    def third_reading
      if says?("read a third time", "third reading")
        settle(6, "THIRD_READING_PASSING", "Question is that the bill be read a third time (passing the chamber).")
      elsif says?("be now passed")
        settle(6, "REMAINING_STAGES_PASSING",
               "Question is that the bill be now passed, taking any remaining stages together (passing the chamber).")
      end
    end

    # Second reading wording covers two different votes: agreeing to the bill's main idea
    # (Template 29), or an amendment to that motion, which records an opinion without changing the
    # bill's text (Template 2). Only the question's own words separate them, so the amendment is
    # settled when they name it, the second reading when they are its own form and nothing else
    # ("That the bill be now read a second time", with no amendment and not "as amended"), and the
    # pair is fenced when they are neither. Fencing the plain form only cost a model decision and a
    # chance to get it wrong (KI-51).
    def second_reading_amendment
      return unless second_reading? && (names_amendment? || says?("words after", "declining"))

      settle(2, "SECOND_READING_AMENDMENT_DIRECT",
             "Question includes both second reading and amendment or words omission.")
    end

    def second_reading
      return unless second_reading?

      plain = text.match?(/\b(?:be\s+(?:now\s+)?|now\s+be\s+)read\s+a\s+second\s+time\b/) && !says?("as amended")
      if plain
        return settle(29, "SECOND_READING_QUESTION",
                      "Question is that the bill be read a second time, and names no amendment.")
      end

      fence([2, 29], "SECOND_READING_NUANCE",
            "Second reading question: could be the second reading itself (Template 29) or a second reading " \
            "amendment (Template 2).#{heading_lockout_note}",
            forbidden: heading_lockout)
    end

    # Template 28: "That the [unit] stand as printed", the inverted question the Senate uses in
    # committee of the whole to decide an amendment that would omit part of a bill. The Senate
    # guide (Guide No. 16, Consideration of legislation) sets out both why the question is put
    # this way and why the inversion has to be carried through here:
    #
    #   "The question on an amendment to delete a clause, item or proposed new section (or a
    #   larger unit such as a Subdivision, Division, Part or Schedule) is put in the form
    #   'That the [unit] stand as printed'. This is designed to test whether the unit has
    #   majority support. An equally divided vote on that question results in it being
    #   decided in the negative and the unit being removed from the bill."
    #
    # So voting the question down is what omits the unit. Reporting the division as though a
    # defeated question meant a defeated amendment states the opposite of what happened to the
    # bill, which is why this gets its own template rather than being folded into 3 or 4.
    def stand_as_printed
      return unless unit_stands_as_printed?

      settle(28, "STAND_AS_PRINTED_OMISSION",
             "Question is that a clause or other unit of the bill stand as printed, so it decides an amendment " \
             "to omit that unit and a vote against the question is what removes it.")
    end

    # An amendment with no stage named. Each chamber amends at its own stage (the Senate in
    # committee, the House in consideration in detail), so the chamber narrows the shortlist and
    # a stage named in the surrounding debate settles it outright. The chair often puts a second
    # reading amendment only by reference ("the amendment moved by the honourable member for
    # Exampleton be agreed to"), and a deferred run of them has no debate beside it, but the
    # section heading still names the stage.
    def amendment_stage
      return unless names_amendment?

      stages = if heading.include?("second reading")
                 [2]
               elsif context.include?("in committee") || context.include?("committee of the whole")
                 [3]
               elsif context.include?("consideration in detail")
                 [4]
               else
                 amendment_stages
               end
      reason = "Amendment question identified. Stage candidates: #{stages}."
      return settle(stages.first, "AMENDMENT_STAGE_NUANCE", reason) if stages.size == 1

      fence(stages, "AMENDMENT_STAGE_NUANCE", reason)
    end

    # Template 13: referral to an existing standing or joint committee, as against appointing a
    # new select committee (12). A signature, but kept below the amendment rules, so a question on
    # an amendment that proposes a referral stays an amendment.
    def committee_referral
      return unless says?("referred to") && says?("committee")

      settle(13, "COMMITTEE_REFERRAL", "Question refers a matter to a standing or joint committee.")
    end

    # ---------------------------------------------------------------------------------------
    # Fallback
    # ---------------------------------------------------------------------------------------

    # Parliament votes on plenty that fits no pattern, so an unmatched question falls to the
    # general motion template rather than failing the run. The guillotine lockout still applies:
    # the heading can mislead the extractor here as readily as anywhere else.
    def general_motion_fallback
      reason = "Unmatched specific procedural pattern; default candidate is General Motion (Template 15)."
      RoutingDecision.default([15], rule_name: FALLBACK, reason: "#{reason}#{heading_lockout_note}",
                                    forbidden: heading_lockout)
    end

    # ---------------------------------------------------------------------------------------
    # Reading the question
    # ---------------------------------------------------------------------------------------

    # Lowercased, with punctuation turned to spaces, so the rules can match plain phrases.
    def plain(words)
      words.downcase.gsub(/[^\w\s]/, " ").gsub(/\s+/, " ").strip
    end

    def says?(*phrases)
      phrases.any? { |phrase| text.include?(phrase) }
    end

    def senate?
      @senate
    end

    def house?
      @house
    end

    # Whether the question is on an amendment, judged outside any bill title (see BILL_TITLE).
    def names_amendment?
      @text_outside_titles.include?("amendment")
    end

    def member_heard?
      says?("no longer heard", "be no longer heard", "be heard now", "be further heard")
    end

    def second_reading?
      says?("read a second time", "second reading")
    end

    # "That the bill stand as printed" is the final question in committee when no amendments have
    # been agreed to, the counterpart of "That the bill, as amended, be agreed to" (Senate Guide
    # No. 16). It omits nothing and carries no inversion, so it is not a unit standing as printed.
    def unit_stands_as_printed?
      says?("stand as printed") && !text.match?(/\bbill stand as printed\b/)
    end

    def substantive_amendment?
      names_amendment? || says?("words after", "words be omitted", "stand as printed")
    end

    def guillotine_heading?
      heading.include?("limitation of debate") || heading.include?("guillotine")
    end

    def heading_lockout
      guillotine_heading? ? [18] : []
    end

    def heading_lockout_note
      guillotine_heading? ? HEADING_LOCKOUT_NOTE : ""
    end

    def amendment_stages
      if senate?
        [2, 3]
      elsif house?
        [2, 4]
      else
        [2, 3, 4]
      end
    end

    def settle(template_id, rule_name, reason)
      RoutingDecision.settled(template_id, rule_name: rule_name, reason: reason)
    end

    def fence(allowed, rule_name, reason, forbidden: [])
      RoutingDecision.fenced(allowed, rule_name: rule_name, reason: reason, forbidden: forbidden)
    end
  end
end
