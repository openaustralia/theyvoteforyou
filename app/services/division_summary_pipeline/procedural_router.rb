# frozen_string_literal: true

module DivisionSummaryPipeline
  # A decision is either settled here (is_deterministic) or fenced: candidate_templates is
  # the set the extractor may choose from and locked_out_templates is what it may not choose
  # even so, both re-checked by ProvenanceValidator#check_routing_fence. rule_name and reason
  # are recorded so a reviewer can tell why a division was classified as it was.
  #
  # advisory_candidates marks a shortlist as a default rather than a constraint, so the fence
  # is not enforced against it. Only the general-motion fallback sets it: reaching that rule
  # means no pattern matched, so an extractor that recognises the motion is better informed
  # than the default, whereas every other shortlist is positive evidence about the question.
  ProceduralDecision = Struct.new(
    :is_deterministic,
    :template_id,
    :candidate_templates,
    :locked_out_templates,
    :rule_name,
    :reason,
    :advisory_candidates,
    keyword_init: true
  ) do
    def requires_nuance?
      !is_deterministic
    end
  end

  # Stage 2: classifies a division from the Speaker's Question alone, before any LLM runs.
  #
  # What a division decided is fixed by the one sentence the chair puts to the chamber ("The
  # question is that..."), not by the Hansard heading above it or the subject being argued
  # about. Anchoring here is what defeats the heading traps below. Chamber, heading and
  # surrounding debate only narrow cases the question leaves genuinely open.
  #
  # These rules live in code rather than in the prompt because they are stable and knowable,
  # and because a model asked to classify freely handles the easy cases and fails the traps.
  # Rules are matched in order, first match wins, so ordering is part of the logic.
  #
  # Keep this a router. Everything genuinely ambiguous belongs to the extractor inside a
  # fence, not to more rules here (ARCHITECTURE.md, constraint 3).
  class ProceduralRouter
    def self.route(speaker_question:, chamber: "", debate_heading: "", hansard_snippet: "")
      q = speaker_question.to_s.strip.downcase
      heading = debate_heading.to_s.strip.downcase
      context = hansard_snippet.to_s.strip.downcase
      norm_chamber = chamber.to_s.strip.downcase

      is_senate = norm_chamber.include?("senate")
      is_house = norm_chamber.include?("representative") || norm_chamber.include?("reps")

      # Clean punctuation from question for uniform pattern matching
      q_clean = q.gsub(/[^\w\s]/, " ").gsub(/\s+/, " ").strip

      # -----------------------------------------------------------------
      # 1. IMMEDIATE PROCEDURAL TRAPS (Pure deterministic matches)
      #
      # Ordering matters: these catch-alls are checked before any subject-matter rule below,
      # because each of them decides only its own procedure and nothing about the underlying
      # question. A suspension question that mentions a censure ("that so much of the standing
      # orders be suspended as would prevent me from moving a censure motion") is a vote about
      # suspending the standing orders, not a censure vote - the censure division, if the
      # suspension carries, is a separate division that arrives here on its own.
      #
      # Suspension (17) is therefore first of all, then closure (22); see the comment on the
      # suspension rule for why that pair is ordered the way it is.
      # -----------------------------------------------------------------

      # Template 17: Suspension of standing orders (the chamber's own rulebook). Decides only
      # that the rules are set aside, not the merits of whatever is then moved under them.
      #
      # This is first in the whole router, and has to be. A suspension question recites the
      # motion it would clear the way for ("That so much of the standing orders be suspended
      # as would prevent ...", House Guide p. 2), so it contains the trigger words of whatever
      # rule covers that motion - including the closure rule immediately below, since
      # suspensions are routinely moved to let a question be put forthwith. Any rule placed
      # above this one reports the suspension division as the thing it merely enabled.
      if q_clean.include?("standing orders be suspended") ||
         q_clean.include?("standing and sessional orders be suspended") ||
         q_clean.include?("suspend standing orders") ||
         q_clean.include?("so much of the standing")
        return ProceduralDecision.new(
          is_deterministic: true,
          template_id: 17,
          candidate_templates: [17],
          locked_out_templates: [],
          rule_name: "SUSPENSION_OF_STANDING_ORDERS",
          reason: "Question moves to suspend standing or sessional orders."
        )
      end

      # Template 22: Closure of debate. Decides only that debate ends now, never the matter
      # under debate, which is usually put in a separate division moments later.
      # Also covers calling on the business of the day to terminate an MPI (House S.O. 46(e)),
      # and the "That the ballot be taken now" form used to closure debate during the election
      # of a Speaker (House S.O. 11(h), Guide p. 41).
      if q_clean.include?("question be now put") ||
         q_clean.include?("question be put") ||
         q_clean.include?("now put") ||
         q_clean.include?("ballot be taken now") ||
         q_clean.include?("business of the day be called on")
        reason = if q_clean.include?("business of the day")
                   "Question calls on the business of the day to terminate discussion."
                 elsif q_clean.include?("ballot be taken now")
                   "Question closures debate on the election of the Speaker so the ballot is taken."
                 else
                   "Question explicitly moves that the question be now put."
                 end
        return ProceduralDecision.new(
          is_deterministic: true,
          template_id: 22,
          candidate_templates: [22],
          locked_out_templates: [],
          rule_name: "CLOSURE_OF_DEBATE",
          reason: reason
        )
      end

      # Template 23: Member be no longer heard (or heard now / further heard). This closure-like gag exists
      # only in the House of Representatives - the Senate doesn't have it - so a match inside the Senate
      # means the chamber metadata or the question is wrong somewhere. Fence it for the extractor rather
      # than asserting it, and say why in the reason.
      if q_clean.include?("no longer heard") || q_clean.include?("be no longer heard") ||
         q_clean.include?("be heard now") || q_clean.include?("be further heard")
        if is_senate
          return ProceduralDecision.new(
            is_deterministic: false,
            template_id: nil,
            candidate_templates: [23],
            locked_out_templates: [],
            rule_name: "MEMBER_NO_LONGER_HEARD_CHAMBER_CONFLICT",
            reason: "Question concerns whether the member be heard, but this motion is a House of Representatives procedure and this division is in the Senate. Verify the chamber before using Template 23."
          )
        end

        return ProceduralDecision.new(
          is_deterministic: true,
          template_id: 23,
          candidate_templates: [23],
          locked_out_templates: [],
          rule_name: "MEMBER_NO_LONGER_HEARD",
          reason: "Question explicitly asks whether the member be heard or no longer heard."
        )
      end

      # Template 24: Suspension of a member (Disciplinary naming and suspension, House S.O. 94 / Senate S.O. 203).
      if q_clean.include?("suspended from the service") || q_clean.include?("suspended from the sitting")
        return ProceduralDecision.new(
          is_deterministic: true,
          template_id: 24,
          candidate_templates: [24],
          locked_out_templates: [],
          rule_name: "SUSPENSION_OF_MEMBER",
          reason: "Question is for the disciplinary suspension of a member."
        )
      end

      # Template 25: Dissent from a ruling of the Chair. Objection to a ruling must be taken at once
      # by a motion of dissent submitted in writing (House S.O. 87). The Senate has the same device;
      # the Guides to Senate Procedure don't give its standing order number, so none is cited here.
      if q_clean.include?("ruling be dissented from") ||
         q_clean.include?("dissent from the ruling") ||
         q_clean.include?("dissent from the chair") ||
         (q_clean.include?("dissent") && q_clean.include?("ruling"))
        return ProceduralDecision.new(
          is_deterministic: true,
          template_id: 25,
          candidate_templates: [25],
          locked_out_templates: [],
          rule_name: "DISSENT_FROM_RULING",
          reason: "Question dissents from a ruling of the Chair."
        )
      end

      # Template 26: Adjournment of the chamber. In the House the Speaker proposes "That the House do
      # now adjourn" at the time set for the adjournment (House S.O. 29, S.O. 31); the Senate has the
      # equivalent in its routine of business.
      if q_clean.include?("do now adjourn") ||
         q_clean.include?("house do now adjourn") ||
         q_clean.include?("senate do now adjourn")
        return ProceduralDecision.new(
          is_deterministic: true,
          template_id: 26,
          candidate_templates: [26],
          locked_out_templates: [],
          rule_name: "ADJOURNMENT_OF_CHAMBER",
          reason: "Question is that the chamber do now adjourn."
        )
      end

      # Template 27: Taking note of documents, committee reports, ministerial statements or answers
      # (House S.O. 202(a); Senate motions to take note of answers are debated under Senate S.O. 72(4)).
      if q_clean.include?("take note of")
        return ProceduralDecision.new(
          is_deterministic: true,
          template_id: 27,
          candidate_templates: [27],
          locked_out_templates: [],
          rule_name: "TAKE_NOTE",
          reason: "Question is to take note of a document, report, explanation or answer."
        )
      end

      # Template 1: First reading, the formal introduction of a bill. Carries no view on the
      # bill's merits, which is exactly what a reader is liable to assume it does.
      if q_clean.include?("read a first time") || q_clean.include?("first reading")
        return ProceduralDecision.new(
          is_deterministic: true,
          template_id: 1,
          candidate_templates: [1],
          locked_out_templates: [],
          rule_name: "FIRST_READING",
          reason: "Question is for the bill to be read a first time."
        )
      end

      # Template 20: Withdrawal of business, removing an item from the Notice Paper (the
      # chamber's list of scheduled business) so it is not dealt with.
      #
      # "be withdrawn" also appears inside second reading amendments, because two of the
      # standard reasoned-amendment forms are "the bill be withdrawn and redrafted to provide
      # for ..." and "the bill be withdrawn and a select committee be appointed to inquire
      # into ..." (House Guide to Procedures pp. 68-69). Those are votes on an amendment to
      # the second reading motion, not on withdrawing business from the Notice Paper, so a
      # question that also names a bill stage or an amendment is left to the stage rules below.
      is_bill_stage_wording = q_clean.include?("read a second time") ||
                              q_clean.include?("second reading") ||
                              q_clean.include?("read a third time") ||
                              q_clean.include?("third reading") ||
                              q_clean.include?("amendment") ||
                              q_clean.include?("words after")

      if !is_bill_stage_wording &&
         (q_clean.include?("withdrawal of") || q_clean.include?("be withdrawn") || q_clean.include?("withdraw notice"))
        return ProceduralDecision.new(
          is_deterministic: true,
          template_id: 20,
          candidate_templates: [20],
          locked_out_templates: [],
          rule_name: "WITHDRAWAL_OF_BUSINESS",
          reason: "Question concerns withdrawing business or notices from the notice paper."
        )
      end

      # Template 21: Parliamentary zone works, which the Parliament Act 1974 requires both
      # houses to approve by resolution.
      if q_clean.include?("parliamentary zone") || q_clean.include?("parliament act 1974")
        return ProceduralDecision.new(
          is_deterministic: true,
          template_id: 21,
          candidate_templates: [21],
          locked_out_templates: [],
          rule_name: "PARLIAMENTARY_ZONE_WORKS",
          reason: "Question approves capital works within the Parliamentary Zone."
        )
      end

      # Template 9: Disallowance motion. Regulations are law the government makes under
      # powers an Act gives it, without a fresh vote; disallowing one strips its legal force.
      if q_clean.include?("disallow") || q_clean.include?("disallowance")
        return ProceduralDecision.new(
          is_deterministic: true,
          template_id: 9,
          candidate_templates: [9],
          locked_out_templates: [],
          rule_name: "DISALLOWANCE_MOTION",
          reason: "Question explicitly moves to disallow a delegated legislative instrument."
        )
      end

      # Template 8: Production of documents. The chamber ordering the government to hand over
      # papers it holds. Wording varies between the chambers' orders for the
      # production of documents, so tolerate "papers" as well as "documents", and "laid upon the
      # table" as well as "laid on the table". These votes are about access to the documents, never
      # about the subject the documents deal with, so a missed match here would misroute badly.
      if q_clean.include?("production of documents") ||
         q_clean.include?("production of papers") ||
         q_clean.include?("order for the production") ||
         q_clean.include?("produce documents") ||
         (q_clean.include?("documents") && q_clean.include?("laid on the table")) ||
         (q_clean.include?("papers") &&
           (q_clean.include?("laid on the table") || q_clean.include?("laid upon the table")))
        return ProceduralDecision.new(
          is_deterministic: true,
          template_id: 8,
          candidate_templates: [8],
          locked_out_templates: [],
          rule_name: "PRODUCTION_OF_DOCUMENTS",
          reason: "Question orders the government to produce documents or papers."
        )
      end

      # Template 10: Censure motion, a formal expression of disapproval of a minister or
      # member carrying no legal effect. Motions of no confidence in a minister or member
      # (often worded "want of confidence") are the same class of vote.
      # When one is moved under a suspension of standing orders, the
      # suspension rule above still catches the suspension division first, by design.
      if q_clean.include?("censure") || q_clean.include?("reprimand") ||
         q_clean.include?("no confidence") || q_clean.include?("want of confidence")
        return ProceduralDecision.new(
          is_deterministic: true,
          template_id: 10,
          candidate_templates: [10],
          locked_out_templates: [],
          rule_name: "CENSURE_MOTION",
          reason: "Question expresses censure or reprimand of a Minister or Member, or want of confidence in them."
        )
      end

      # Template 11: Estimates committees, which question officials about planned department
      # spending. These votes organise that scrutiny; they do not decide the spending.
      if q_clean.include?("estimates") && (q_clean.include?("committee") || q_clean.include?("budget"))
        return ProceduralDecision.new(
          is_deterministic: true,
          template_id: 11,
          candidate_templates: [11],
          locked_out_templates: [],
          rule_name: "ESTIMATES_COMMITTEES",
          reason: "Question concerns referring or managing Budget considerations by Estimates committees."
        )
      end

      # Template 12: Establishing a select committee, appointed to inquire into one subject
      # and disband once it reports. Distinct from a referral to a standing committee (13).
      if q_clean.include?("select committee") &&
         (q_clean.include?("appoint") || q_clean.include?("establish") || q_clean.include?("inquire"))
        return ProceduralDecision.new(
          is_deterministic: true,
          template_id: 12,
          candidate_templates: [12],
          locked_out_templates: [],
          rule_name: "SELECT_COMMITTEE",
          reason: "Question establishes or appoints a Select Committee."
        )
      end

      # Template 14: Selection of Bills Committee, the Senate committee that recommends which
      # bills other committees should examine before the Senate votes on them.
      if q_clean.include?("selection of bills")
        return ProceduralDecision.new(
          is_deterministic: true,
          template_id: 14,
          candidate_templates: [14],
          locked_out_templates: [],
          rule_name: "SELECTION_OF_BILLS",
          reason: "Question adopts a report of the Selection of Bills Committee."
        )
      end

      if q_clean.include?("selection committee") && is_house
        return ProceduralDecision.new(
          is_deterministic: true,
          template_id: 19,
          candidate_templates: [19],
          locked_out_templates: [],
          rule_name: "REARRANGEMENT_OF_BUSINESS",
          reason: "Question adopts determinations of the House Selection Committee rearranging business."
        )
      end

      # Template 16: Matter of urgency, the Senate's device for setting aside time to debate
      # an issue immediately. Decides that the debate happens, not the issue.
      if q_clean.include?("matter of urgency") || q_clean.include?("urgency motion")
        return ProceduralDecision.new(
          is_deterministic: true,
          template_id: 16,
          candidate_templates: [16],
          locked_out_templates: [],
          rule_name: "MATTER_OF_URGENCY",
          reason: "Question declares an issue a Matter of Urgency (Senate)."
        )
      end

      # Template 19: Rearrangement of business. This also covers adjourning or postponing
      # debate on a bill or motion ("that the debate be adjourned", "the second reading be
      # made an order of the day for the next sitting"). Those questions often name a bill
      # stage, so they must be caught here, before the second reading and amendment rules
      # below fence them between Templates 2 and 6 as though the bill itself were being
      # decided.
      if q_clean.include?("rearrangement of business") ||
         q_clean.include?("postpone") ||
         q_clean.include?("order of the day be postponed") ||
         q_clean.include?("order of the day for the next") ||
         q_clean.include?("debate be adjourned") ||
         q_clean.include?("debate be now adjourned") ||
         q_clean.include?("adjourn the debate") ||
         q_clean.include?("business of the senate be rearranged")
        return ProceduralDecision.new(
          is_deterministic: true,
          template_id: 19,
          candidate_templates: [19],
          locked_out_templates: [],
          rule_name: "REARRANGEMENT_OF_BUSINESS",
          reason: "Question rearranges or postpones parliamentary orders of business."
        )
      end

      # Template 5: Report from the Federation Chamber, or resolution of an unresolved question (House S.O. 188).
      if (q_clean.include?("federation chamber") && (q_clean.include?("report") || q_clean.include?("agreed to"))) ||
         q_clean.include?("unresolved question") || heading.include?("unresolved question")
        return ProceduralDecision.new(
          is_deterministic: true,
          template_id: 5,
          candidate_templates: [5],
          locked_out_templates: [],
          rule_name: "FEDERATION_CHAMBER_REPORT",
          reason: "Question formally agrees to a report or resolves an unresolved question from the Federation Chamber."
        )
      end

      # Template 7: Consideration of a message. A bill must pass both houses in identical
      # words, so a house that amends one sends the other a "message" to accept, reject, insist or request.
      is_message_pattern = q_clean.include?("amendments made by the senate") ||
                           q_clean.include?("amendments made by the house") ||
                           q_clean.include?("senate message") ||
                           q_clean.include?("house message") ||
                           q_clean.include?("consideration of senate amendments") ||
                           q_clean.include?("insist on its amendment") ||
                           q_clean.include?("insists on its amendment") ||
                           q_clean.include?("does not insist") ||
                           q_clean.include?("disagree to the amendment") ||
                           q_clean.include?("disagreed to and an amendment") ||
                           (q_clean.include?("disagreed to") && q_clean.include?("amendment")) ||
                           q_clean.include?("requested amendment") ||
                           q_clean.include?("requests be made") ||
                           q_clean.include?("press its request")

      if is_message_pattern
        return ProceduralDecision.new(
          is_deterministic: true,
          template_id: 7,
          candidate_templates: [7],
          locked_out_templates: [],
          rule_name: "CONSIDERATION_OF_MESSAGE",
          reason: "Question resolves amendments, messages, disagreements, or requests between the chambers."
        )
      end

      # -----------------------------------------------------------------
      # 2. GUILLOTINE TRAP AVOIDANCE
      #
      # The misclassification this whole stage exists to prevent. A "guillotine" caps the
      # time left for debate, and a "Limitation of Debate" heading then covers every division
      # that follows while it runs, substantive amendment and bill votes included. Reported
      # as time-limit procedure, those votes tell a reader the opposite of what their
      # representative actually decided.
      #
      # The heading alone therefore never identifies a guillotine motion: only a question
      # that is itself about limiting the time for debate does. Wherever routing stays
      # ambiguous below, Template 18 is fenced off so the extractor cannot land on it from
      # the heading alone.
      # -----------------------------------------------------------------
      is_heading_guillotine = heading.include?("limitation of debate") || heading.include?("guillotine")
      is_substantive_amendment = q_clean.include?("amendment") ||
                                 q_clean.include?("words after") ||
                                 q_clean.include?("words be omitted") ||
                                 q_clean.include?("stand as printed")

      # A guillotine heading over an amendment question: a substantive vote on the bill. The
      # extractor sees the same misleading heading, so Template 18 is banned outright rather
      # than merely left off the shortlist.
      if is_heading_guillotine && is_substantive_amendment
        # A "stand as printed" question is already unambiguous about its stage and its
        # inversion, so the guillotine heading only has to be stopped from overriding it.
        candidates = if q_clean.include?("stand as printed") && !q_clean.match?(/\bbill stand as printed\b/)
                       [28]
                     elsif is_senate
                       [2, 3]
                     elsif is_house
                       [2, 4]
                     else
                       [2, 3, 4]
                     end

        return ProceduralDecision.new(
          is_deterministic: false,
          template_id: nil,
          candidate_templates: candidates,
          locked_out_templates: [18],
          rule_name: "GUILLOTINE_TRAP_AVOIDED",
          reason: "Heading was 'Limitation of Debate', but the question is on an amendment. Template 18 locked out."
        )
      end

      # Template 18 is only ever reached this way, from a question about the time limit
      # itself. Never from the heading a division happens to sit under.
      #
      # The House guillotine is two questions, not one (House S.O.s 82-84, Guide pp. 74-75): a
      # Minister declares the bill urgent, "That the bill be considered urgent" is put
      # immediately with no debate or amendment, and only then may a motion allotting time be
      # moved. Both questions are about how long the chamber spends on the business rather
      # than about the business, so both belong here; without the first form they fell through
      # to the general-motion fallback and were described as opinion-only motions
      # (KNOWN_ISSUES.md, KI-4). "Matter of urgency" is a different thing entirely and is
      # matched by its own rule further up, before this one is reached.
      is_declaration_of_urgency = q_clean.include?("be considered urgent") ||
                                  q_clean.include?("be considered an urgent bill") ||
                                  q_clean.include?("declaration of urgency")

      if q_clean.include?("time allotted") ||
         q_clean.include?("allotment of time") ||
         q_clean.include?("limitation of debate") ||
         is_declaration_of_urgency ||
         (q_clean.include?("guillotine") && !is_substantive_amendment)
        return ProceduralDecision.new(
          is_deterministic: true,
          template_id: 18,
          candidate_templates: [18],
          locked_out_templates: [],
          rule_name: "GUILLOTINE_PROCEDURE",
          reason: if is_declaration_of_urgency
                    "Question declares the bill urgent, the first of the two questions that impose a House time limit."
                  else
                    "Question is the limitation of debate (time allocation) itself."
                  end
        )
      end

      # -----------------------------------------------------------------
      # 3. NUANCED ROUTING (Fencing candidates for Semantic Extractor)
      #
      # What remains are the bill stages, where one form of words can mean two different
      # votes. A bill is read three times in each chamber: the first reading introduces it,
      # the second reading settles its main idea, the third passes it out of the chamber.
      # These rules narrow as far as the wording honestly allows and fence the rest.
      # -----------------------------------------------------------------

      # Template 6: third reading, so the bill leaves this chamber for the other one.
      if q_clean.include?("read a third time") || q_clean.include?("third reading")
        return ProceduralDecision.new(
          is_deterministic: true,
          template_id: 6,
          candidate_templates: [6],
          locked_out_templates: [],
          rule_name: "THIRD_READING_PASSING",
          reason: "Question is that the bill be read a third time (passing the chamber)."
        )
      end

      # Second reading wording covers two different votes: agreeing to the bill's main idea
      # (Template 6), or an amendment to that motion, which records an opinion without
      # changing the bill's text (Template 2). Only the question's own words separate them.
      if q_clean.include?("read a second time") || q_clean.include?("second reading")
        if q_clean.include?("amendment") || q_clean.include?("words after") || q_clean.include?("declining")
          return ProceduralDecision.new(
            is_deterministic: true,
            template_id: 2,
            candidate_templates: [2],
            locked_out_templates: [],
            rule_name: "SECOND_READING_AMENDMENT_DIRECT",
            reason: "Question includes both second reading and amendment or words omission."
          )
        end

        return ProceduralDecision.new(
          is_deterministic: false,
          template_id: nil,
          candidate_templates: [2, 6],
          locked_out_templates: is_heading_guillotine ? [18] : [],
          rule_name: "SECOND_READING_NUANCE",
          reason: if is_heading_guillotine
                    "Second reading question: could be passing second reading (Template 6) or second reading amendment (Template 2). Heading was 'Limitation of Debate', so Template 18 is locked out."
                  else
                    "Second reading question: could be passing second reading (Template 6) or second reading amendment (Template 2)."
                  end
        )
      end

      # Template 28: "That the [unit] stand as printed", the inverted question the Senate uses in
      # committee of the whole to decide an amendment that would omit part of a bill.
      #
      # The Senate guide (Guide No. 16, Consideration of legislation) sets out both why the
      # question is put this way and why the inversion has to be carried through here:
      #
      #   "The question on an amendment to delete a clause, item or proposed new section (or a
      #   larger unit such as a Subdivision, Division, Part or Schedule) is put in the form
      #   'That the [unit] stand as printed'. This is designed to test whether the unit has
      #   majority support. An equally divided vote on that question results in it being
      #   decided in the negative and the unit being removed from the bill."
      #
      # So voting the question down is what omits the unit. Reporting the division as though a
      # defeated question meant a defeated amendment states the opposite of what happened to
      # the bill, which is why this gets its own template rather than being folded into 3 or 4.
      #
      # "That the bill stand as printed" is deliberately excluded: per the same guide that is
      # the final question in committee when no amendments have been agreed to, the counterpart
      # of "That the bill, as amended, be agreed to". It omits nothing and carries no inversion.
      if q_clean.include?("stand as printed") && !q_clean.match?(/\bbill stand as printed\b/)
        return ProceduralDecision.new(
          is_deterministic: true,
          template_id: 28,
          candidate_templates: [28],
          locked_out_templates: [],
          rule_name: "STAND_AS_PRINTED_OMISSION",
          reason: "Question is that a clause or other unit of the bill stand as printed, so it decides an amendment to omit that unit and a vote against the question is what removes it."
        )
      end

      # An amendment with no stage named. Each chamber amends at its own stage (the Senate
      # in committee, the House in consideration in detail), so the chamber narrows the
      # shortlist and a stage named in the surrounding debate settles it outright.
      if q_clean.include?("amendment") || q_clean.include?("amendments be agreed to")
        candidates = if is_senate
                       [2, 3]
                     elsif is_house
                       [2, 4]
                     else
                       [2, 3, 4]
                     end

        if context.include?("in committee") || context.include?("committee of the whole")
          candidates = [3]
        elsif context.include?("consideration in detail")
          candidates = [4]
        end

        return ProceduralDecision.new(
          is_deterministic: candidates.length == 1,
          template_id: candidates.length == 1 ? candidates.first : nil,
          candidate_templates: candidates,
          locked_out_templates: [],
          rule_name: "AMENDMENT_STAGE_NUANCE",
          reason: "Amendment question identified. Stage candidates: #{candidates}."
        )
      end

      # Template 13: referral to an existing standing or joint committee, as against
      # appointing a new select committee (12).
      if q_clean.include?("referred to") && q_clean.include?("committee")
        return ProceduralDecision.new(
          is_deterministic: true,
          template_id: 13,
          candidate_templates: [13],
          locked_out_templates: [],
          rule_name: "COMMITTEE_REFERRAL",
          reason: "Question refers a matter to a standing or joint committee."
        )
      end

      # Parliament votes on plenty that fits no pattern, so an unmatched question falls to
      # the general motion template rather than failing the run. The guillotine lockout still
      # applies: the heading can mislead the extractor here as readily as anywhere else.
      ProceduralDecision.new(
        is_deterministic: false,
        template_id: nil,
        candidate_templates: [15],
        locked_out_templates: is_heading_guillotine ? [18] : [],
        advisory_candidates: true,
        rule_name: "GENERAL_MOTION_FALLBACK",
        reason: if is_heading_guillotine
                  "Unmatched specific procedural pattern; default candidate is General Motion (Template 15). Heading was 'Limitation of Debate', so Template 18 is locked out."
                else
                  "Unmatched specific procedural pattern; default candidate is General Motion (Template 15)."
                end
      )
    end
  end
end
