# frozen_string_literal: true

module DivisionSummaryPipeline
  # ProceduralDecision records the outcome of the procedural state machine routing.
  ProceduralDecision = Struct.new(
    :is_deterministic,
    :template_id,
    :candidate_templates,
    :locked_out_templates,
    :rule_name,
    :reason,
    keyword_init: true
  ) do
    def requires_nuance?
      !is_deterministic
    end
  end

  # ProceduralRouter anchors parliamentary classification to the single source
  # of procedural truth: the Speaker's Question ("The question is that...").
  #
  # It catches deterministic procedural traps directly in code, defeats the
  # "Limitation of Debate" (guillotine) trap, and fences candidate templates
  # for ambiguous stages so the LLM operates within strict boundaries.
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
      # -----------------------------------------------------------------

      # Template 23: Member be no longer heard. This closure-like gag exists only in the House of
      # Representatives - the Senate doesn't have it - so a match inside the Senate means the
      # chamber metadata or the question is wrong somewhere. Fence it for the extractor rather
      # than asserting it, and say why in the reason.
      if q_clean.include?("no longer heard") || q_clean.include?("be no longer heard")
        if is_senate
          return ProceduralDecision.new(
            is_deterministic: false,
            template_id: nil,
            candidate_templates: [23],
            locked_out_templates: [],
            rule_name: "MEMBER_NO_LONGER_HEARD_CHAMBER_CONFLICT",
            reason: "Question asks that the member be no longer heard, but this motion is a House of Representatives procedure and this division is in the Senate. Verify the chamber before using Template 23."
          )
        end

        return ProceduralDecision.new(
          is_deterministic: true,
          template_id: 23,
          candidate_templates: [23],
          locked_out_templates: [],
          rule_name: "MEMBER_NO_LONGER_HEARD",
          reason: "Question explicitly asks that the member be no longer heard."
        )
      end

      # Template 22: Closure of debate ("That the question be now put")
      if q_clean.include?("question be now put") || q_clean.include?("now put")
        return ProceduralDecision.new(
          is_deterministic: true,
          template_id: 22,
          candidate_templates: [22],
          locked_out_templates: [],
          rule_name: "CLOSURE_OF_DEBATE",
          reason: "Question explicitly moves that the question be now put."
        )
      end

      # Template 17: Suspension of standing orders
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

      # Template 1: First reading
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

      # Template 20: Withdrawal of business
      if q_clean.include?("withdrawal of") || q_clean.include?("be withdrawn") || q_clean.include?("withdraw notice")
        return ProceduralDecision.new(
          is_deterministic: true,
          template_id: 20,
          candidate_templates: [20],
          locked_out_templates: [],
          rule_name: "WITHDRAWAL_OF_BUSINESS",
          reason: "Question concerns withdrawing business or notices from the notice paper."
        )
      end

      # Template 21: Parliamentary zone works
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

      # Template 9: Disallowance motion
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

      # Template 8: Production of documents. Wording varies between the chambers' orders for the
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

      # Template 10: Censure motion. Motions of no confidence in a minister or member
      # (often worded "want of confidence") are the same class of vote: a formal expression
      # of disapproval. When one is moved under a suspension of standing orders, the
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

      # Template 11: Budget - Estimates committees
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

      # Template 12: Establishing a select committee
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

      # Template 14: Selection of Bills committee
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

      # Template 16: Matter of urgency
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
      # decided. The end-of-day "that the House do now adjourn" is deliberately not matched:
      # it closes the sitting rather than rescheduling business.
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

      # Template 5: Report from Federation Chamber
      if q_clean.include?("federation chamber") && (q_clean.include?("report") || q_clean.include?("agreed to"))
        return ProceduralDecision.new(
          is_deterministic: true,
          template_id: 5,
          candidate_templates: [5],
          locked_out_templates: [],
          rule_name: "FEDERATION_CHAMBER_REPORT",
          reason: "Question formally agrees to a report from the Federation Chamber."
        )
      end

      # Template 7: Agreeing to amendments / message between houses
      if (q_clean.include?("amendments made by the senate") && q_clean.include?("agreed to")) ||
         (q_clean.include?("amendments made by the house") && q_clean.include?("agreed to")) ||
         (q_clean.include?("senate message") && q_clean.include?("agreed to")) ||
         q_clean.include?("consideration of senate amendments")
        return ProceduralDecision.new(
          is_deterministic: true,
          template_id: 7,
          candidate_templates: [7],
          locked_out_templates: [],
          rule_name: "CONSIDERATION_OF_MESSAGE",
          reason: "Question agrees to amendments made by the other chamber (Consideration of a Message)."
        )
      end

      # -----------------------------------------------------------------
      # 2. GUILLOTINE TRAP AVOIDANCE
      #
      # A "Limitation of Debate" heading covers every division that follows while the guillotine
      # is running - substantive amendment and bill votes included. The heading alone therefore
      # never identifies a guillotine motion: only a question that is itself about limiting the
      # time for debate does. Wherever routing stays ambiguous below, Template 18 is fenced off
      # so the extractor cannot land on it from the heading alone.
      # -----------------------------------------------------------------
      is_heading_guillotine = heading.include?("limitation of debate") || heading.include?("guillotine")
      is_substantive_amendment = q_clean.include?("amendment") ||
                                 q_clean.include?("words after") ||
                                 q_clean.include?("words be omitted")

      if is_heading_guillotine && is_substantive_amendment
        candidates = if is_senate
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

      # Question explicitly on the guillotine / time allocation itself
      if q_clean.include?("time allotted") ||
         q_clean.include?("limitation of debate") ||
         (q_clean.include?("guillotine") && !is_substantive_amendment)
        return ProceduralDecision.new(
          is_deterministic: true,
          template_id: 18,
          candidate_templates: [18],
          locked_out_templates: [],
          rule_name: "GUILLOTINE_PROCEDURE",
          reason: "Question is the limitation of debate (time allocation) itself."
        )
      end

      # -----------------------------------------------------------------
      # 3. NUANCED ROUTING (Fencing candidates for Semantic Extractor)
      # -----------------------------------------------------------------

      # Third reading: Passing a Bill (Template 6)
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

      # Second reading question: Could be passing second reading (6) or second reading amendment (2)
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

      # General amendment question
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

      # Committee referral (General)
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

      # Fallback to General Motion (Template 15)
      ProceduralDecision.new(
        is_deterministic: false,
        template_id: nil,
        candidate_templates: [15],
        locked_out_templates: is_heading_guillotine ? [18] : [],
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

