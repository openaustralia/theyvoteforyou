# frozen_string_literal: true

module DivisionSummaryPipeline
  # Everything a summary quotes or names from Hansard, each item as Hansard's own text with a
  # record of where it came from. Stage 4 builds it from what Stage 1 found by rule and from the
  # model's references once they resolve; Stage 5 compiles from it and never sees the model's
  # reply, so nothing unverified can reach a draft.
  #
  # - introduction: the mover's "I move ..." words
  # - motion: the terms moved (nil when none were recorded, which only a question that states
  #   its own terms can stand in for; see ProvenanceValidator#check_motion)
  # - question: the chair's statement putting the question
  # - explanations: passages of the mover's own sentences, in the order spoken
  # - facts: fact name => Excerpt, for the template's named facts (a committee, a regulation)
  # - mover: the ResolvedMember for whoever moved the motion, or nil
  # - limitation: the chair's sentence saying a limitation of debate's time had expired, when the
  #   question was put because it had, or nil. It is not in the transcript, so its unit_ids are
  #   empty.
  # - circulation: the Circulation when the chair put amendments nobody moved, or nil. The motion
  #   is then their terms, as the chair's statement printed them.
  # - closed_template_id: for a closure, the template the motion it cut short settles on, found by
  #   rule (ContextPacket#closed_template_id), or nil.
  # - proposer: who proposed a matter of urgency someone else moved (ContextPacket#proposer), or nil.
  Evidence = Data.define(:introduction, :motion, :question, :explanations, :facts, :mover, :limitation,
                         :circulation, :closed_template_id, :proposer) do
    def initialize(circulation: nil, closed_template_id: nil, proposer: nil, **fields)
      super
    end
  end

  class Evidence
    # found_by: :rule (Stage 1 found it) or :model (a model reference that resolved).
    Excerpt = Data.define(:text, :unit_ids, :speaker, :speaker_gid, :time, :date, :found_by) do
      def self.from_passage(passage, found_by:)
        speech = passage.speech
        new(text: passage.text, unit_ids: passage.unit_ids, speaker: speech.speaker, speaker_gid: speech.speaker_gid,
            time: speech.time, date: speech.date, found_by: found_by)
      end
    end

    def self.empty
      new(introduction: nil, motion: nil, question: nil, explanations: [], facts: {}, mover: nil, limitation: nil)
    end

    def motion_text
      motion&.text
    end

    def question_text
      question&.text
    end

    def fact(name)
      facts[name.to_sym]&.text
    end
  end
end
