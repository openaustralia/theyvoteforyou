# frozen_string_literal: true

module DivisionSummaryPipeline
  # The parts of a summary that quote Hansard, rendered the same way under every template:
  #
  #   About the ...        what the mover said explaining it, each passage as they said it
  #   Motion Introduction  the words they moved it with ("I move the second reading amendment ...")
  #   Motion Text          the terms moved, whole
  #   Question Put         the chair's statement putting the question
  #
  # Each quote is Hansard's own text from Evidence, never shortened or tidied, and each carries
  # the time of the speech it came from, which is not the time of the division. A section with
  # nothing to quote says so in a fixed sentence rather than being filled in.
  class EvidenceSections
    NO_EXPLANATION = "> No explanatory claims recorded."
    NO_INTRODUCTION = "> No motion introduction recorded."
    NO_MOTION = "> No separate motion was recorded; the question put below states it."
    NO_QUESTION = "> No question was recorded before the division."

    # mover_label: how the summary names the mover ("Senator Tyron Whitten"), or nil when the
    # mover is not known. moved: "amendment" or "motion" (TemplateCatalogue).
    def initialize(evidence, facts, mover_label:, moved:)
      @evidence = evidence
      @facts = facts
      @mover_label = mover_label
      @moved = moved
    end

    def explanation
      passages = evidence.explanations
      return NO_EXPLANATION if passages.empty?

      passages.chunk_while { |a, b| same_speech?(a, b) && a.incorporated == b.incorporated }.map do |group|
        excerpt = group.first
        who = mover_label || speaker_label(excerpt)
        # Incorporated by leave, the words are the member's for the record but were not delivered
        # orally in the chamber (Senate Guide No. 10), so they are not said to have been said
        # (KI-55).
        lead = excerpt.incorporated ? "#{who}'s speech, incorporated in Hansard, reads:" : "#{who} said:"
        "#{moment(excerpt)}, #{lead}\n\n#{group.map { |passage| blockquote(passage.text) }.join("\n\n")}"
      end.join("\n\n")
    end

    def introduction
      evidence.introduction ? blockquote(evidence.introduction.text) : NO_INTRODUCTION
    end

    # "Senator Example moved the following amendment:". A motion the model found, rather than
    # Stage 1, is not credited to anyone: the speech it sits in may be the chair reading out
    # someone else's proposal. Amendments the chair put without anyone moving them are never
    # said to have been moved (Circulation).
    def motion_attribution
      motion = evidence.motion
      return "" unless motion
      return circulated_attribution(evidence.circulation) if evidence.circulation
      return "The following #{moved} was moved:" if mover_label.nil? || motion.found_by != :rule

      "#{mover_label} moved the following #{moved}:"
    end

    def motion
      evidence.motion ? blockquote(evidence.motion.text) : NO_MOTION
    end

    def question
      question = evidence.question
      return NO_QUESTION unless question

      "#{moment(question)}, #{chair_label(question)} put the following question:\n\n#{blockquote(question.text)}"
    end

    # The chair saying a limitation of debate's time had expired, or nil when the question was
    # not put because it had. Nothing is printed in its place: most questions are not.
    def limitation
      statement = evidence.limitation
      return nil unless statement

      "#{moment(statement)}, #{chair_label(statement)} said:\n\n#{blockquote(statement.text)}"
    end

    def self.blockquote(text)
      text.to_s.strip.split("\n").map { |line| line.strip.empty? ? ">" : "> #{line.strip}" }.join("\n")
    end

    private

    attr_reader :evidence, :facts, :mover_label, :moved

    def blockquote(text)
      self.class.blockquote(text)
    end

    # "The following amendments, circulated by the Australian Greens, were put:"
    def circulated_attribution(circulation)
      noun, verb = circulation.plural ? %w[amendments were] : %w[amendment was]
      by = circulation.by ? ", circulated by #{circulation.by}," : ""
      "The following #{noun}#{by} #{verb} put:"
    end

    def chair_label(excerpt)
      if excerpt.speaker.blank? then "the chair"
      elsif office?(excerpt.speaker) then office_label(excerpt.speaker)
      else "#{speaker_label(excerpt)}, in the chair,"
      end
    end

    # Unit IDs start with the speech they came from ("S3.4"), so two speeches by the same member
    # in the same minute are still told apart.
    def same_speech?(one, other)
      speech_of(one) == speech_of(other)
    end

    def speech_of(excerpt)
      excerpt.unit_ids.first.to_s[/\AS\d+/]
    end

    # "At 1:27 PM", or "On 12 May 2026 at 5:40 PM" for a speech from an earlier sitting day.
    def moment(excerpt)
      time = ClockTime.display(excerpt.time)
      day = "On #{Date.parse(excerpt.date).strftime('%-d %B %Y')}" if excerpt.date.present? && excerpt.date != facts.date
      return day ? "#{day} at #{time}" : "At #{time}" if time.present?

      day || "Before the division"
    end

    # A speaker's name as TVFY records it, in the site's own form ("Senator Example", "Example
    # MP"; Member#full_name_no_electorate). Only the member record and the chamber are used:
    # Hansard does not record whether the member in the chair was the Speaker, a deputy or a
    # temporary chair, so no office is named ("Example MP, in the chair").
    # Older Hansard names a presiding officer by office ("The PRESIDENT", "The DEPUTY SPEAKER"),
    # which is printed as the office, since there is no person's name to give a title to.
    def office?(speaker)
      speaker.to_s.match?(/\Athe\s/i)
    end

    def office_label(speaker)
      words = speaker.to_s.sub(/\Athe\s+/i, "").split
      "the #{words.map { |word| word.match?(/\A[[:upper:]]+\z/) ? word.capitalize : word }.join(' ')}"
    end

    def speaker_label(excerpt)
      return office_label(excerpt.speaker) if office?(excerpt.speaker)

      resolved = MemberResolver.resolve(gid: excerpt.speaker_gid) if excerpt.speaker_gid.present?
      senator = resolved&.member ? resolved.member.senator? : facts.senate?
      name = resolved&.name.presence || excerpt.speaker
      senator ? "Senator #{name}" : "#{name} MP"
    end
  end
end
