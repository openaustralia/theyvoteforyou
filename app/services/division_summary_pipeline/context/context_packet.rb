# frozen_string_literal: true

module DivisionSummaryPipeline
  # The one object every later stage reads from. Stages 3 to 5 see only this, never the
  # Division or the XML, so whatever is missing here cannot be recovered downstream.
  #
  # - facts: the database facts (DivisionFacts)
  # - heading: the Hansard heading the division sits under, as DataLoader::DivisionXml#name gives it
  # - speaker_question: the question as Stage 2 routes on it: the chair's sentence putting it
  #   (ChairStatement#question), or failing that DataLoader::DivisionXml#operative_question
  # - transcript: the Hansard itself, as units the model can point at (Transcript)
  # - mover: who moved the motion and which speech moved it, found by rule (MoverFinder), or nil
  # - routing: Stage 2's decision (RoutingDecision)
  # - context_level: :immediate, :subdebate or :sitting_day
  # - context_warnings: reasons the speeches beside the division may not be the debate about it
  # - source: :hansard_xml, or :division_record when no XML matched and the packet was built from
  #   the Division record's own stored motion text
  # - division_xml_id: the matched <division> element's id, for the reviewer
  # - limitation_statement: when the question was put because a limitation of debate's time had
  #   expired, the chair's sentence saying so, found by rule, as a hash of :id (the speech's XML
  #   id), :speaker, :speaker_gid, :time and :text; otherwise nil. It is kept out of the
  #   transcript, since the rest of the chair's statement usually puts a question on another bill.
  # - circulation: when the chair put amendments that nobody moved in the chamber, a Circulation
  #   saying who circulated them; otherwise nil
  ContextPacket = Data.define(:facts, :heading, :speaker_question, :transcript, :mover, :routing, :context_level,
                              :context_warnings, :source, :division_xml_id, :limitation_statement, :circulation) do
    def initialize(circulation: nil, **fields)
      super
    end
  end

  class ContextPacket
    # A question that only points at a motion ("the amendment moved by Senator Example be agreed
    # to", "business of the Senate No. 3 ... be agreed to") rather than stating its terms, so the
    # terms have to be found elsewhere for the summary to say what was decided. Opposition and
    # crossbench sheets are numbered ("on sheet 3982", "on sheets 3974, 3975"); the government's
    # carry letters ("on sheet ST128", "IC116 revised", "AD128").
    QUESTION_BY_REFERENCE = /\bmoved\s+by\b|\bin\s+the\s+name\s+of\b|\bbusiness\s+of\s+the\s+senate\s+no\b|
                             \bthe\s+(?:motion|amendments?|proposal|request)\s+(?:moved|as\s+amended|be\s+agreed)\b|
                             \bon\s+sheets?\s+[a-z]*\d/xi

    # Templates the router settles only on a fixed form of words that is the whole of what was
    # decided: first reading, third reading or the bill being passed, closure, the gag, and the
    # adjournment. However such a question is put, there are no separate terms to find.
    QUESTION_IS_THE_MOTION = [1, 6, 22, 23, 26].freeze

    delegate :house, :date, :clock_time, to: :facts

    def division_id
      facts.id
    end

    delegate :question_speech, to: :transcript

    # The transcript's copy of the speech that moved the motion, when it is in the packet.
    def mover_speech
      transcript.speech_with_id(mover&.speech&.dig(:id))
    end

    def earlier_debate_dates
      transcript.earlier_dates
    end

    def question_by_reference?
      speaker_question.to_s.match?(QUESTION_BY_REFERENCE)
    end

    # Whether the chair's question is itself the motion, as in "that the remaining stages of the
    # bill be agreed to, and the bill be now passed", put by the chair when a guillotine's time
    # runs out with nobody moving it. The model is then told not to look for the terms, and the
    # orchestrator does not widen to the whole sitting day to find them: that second call reads
    # tens of thousands of tokens and can only come back with nothing.
    def question_states_motion?
      return false if question_by_reference? || !routing&.deterministic?

      QUESTION_IS_THE_MOTION.include?(routing.template_id)
    end

    # Whether Stage 1 found the terms by rule: moved, in the mover's speech, or put, in the chair's.
    def motion_found?
      terms_moved? || transcript.question_terms_units.any?
    end

    def terms_moved?
      speech = mover_speech
      speech.present? && transcript.last_move_units(speech, :motion).any?
    end
  end
end
