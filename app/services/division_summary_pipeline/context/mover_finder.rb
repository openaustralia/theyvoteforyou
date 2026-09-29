# frozen_string_literal: true

module DivisionSummaryPipeline
  # The member who moved the motion or amendment a division decided, and the terms they moved,
  # found from Hansard by rule rather than by the model (ARCHITECTURE.md, Data classification:
  # member details are Type 1 facts). Before this existed the mover was whoever the model
  # happened to attribute its first claim to, so a draft with no claims said "introduced by a
  # member".
  #
  # The chair usually names the mover when putting the question ("the amendment moved by
  # Senator Example", "the motion moved by the member for Exampleton"), and that is trusted
  # first. Otherwise the motion being put is the one moved just before the question, so only
  # a move in the last few speeches counts: further back it may be a different motion from
  # earlier in the debate, such as an amendment moved before a second reading question. A
  # move found under another of the bill's headings (EarlierDebate's :other_heading) never
  # counts that way, since it belongs to a different stage: under a guillotine the second
  # reading question comes straight after an amendment moved in the second reading debate,
  # and would otherwise be credited to that amendment's mover. Nor does such a move displace a
  # named member's move under this debate's own heading: it is only a fallback.
  #
  # "Business ... standing in the name of Senator Example" names whose notice it is, which is
  # weaker: another senator often moves a notice on the owner's behalf, so a recent move by
  # someone else still wins over it.
  class MoverFinder
    # found_by says how, for the reviewer: :chair_named (the chair named the mover and their move
    # is in the excerpt), :chair_named_only (named, but the move is not in the excerpt),
    # :recent_move (the latest "I move" just before the question) or :notice_owner (the weaker
    # "in the name of" hint, with no move of theirs found).
    Result = Struct.new(:speech, :member, :found_by, keyword_init: true) do
      def moved_text
        speech&.dig(:moved_text)
      end
    end

    # How close to the end of the excerpt an unnamed move must be to count as the motion being
    # put: the move itself, perhaps a seconder, then the chair's question.
    UNNAMED_MOVE_WINDOW = 4

    ELECTORATE_HINT = /moved\s+by\s+the\s+(?:honourable\s+|hon\.?\s+)?member\s+for\s+([A-Z][\w'’-]*(?:[ -][A-Z][\w'’-]*)*)/
    MOVED_BY_HINT = /moved\s+by\s+(?:Senator|Mr|Mrs|Ms|Miss|Dr)\s+(?:the\s+Hon\.?\s+)?([A-Z][\w'’-]*(?:\s+[A-Z][\w'’-]*)*)/
    NOTICE_OWNER_HINT = /in\s+the\s+name\s+of\s+(?:Senator|Mr|Mrs|Ms|Miss|Dr)\s+(?:the\s+Hon\.?\s+)?([A-Z][\w'’-]*(?:\s+[A-Z][\w'’-]*)*)/

    def self.find(question:, speeches:, house: nil, date: nil)
      new(question: question, speeches: speeches, house: house, date: date).find
    end

    def initialize(question:, speeches:, house:, date:)
      @question = question.to_s
      @speeches = Array(speeches)
      @house = house
      @date = date
    end

    def find
      hint = named_mover
      speech = named_move(hint) if hint
      found_by = (hint[:weak] ? :notice_owner : :chair_named) if hint && speech
      if speech.nil? && (hint.nil? || hint[:weak])
        speech = recent_unnamed_move
        found_by = :recent_move if speech
      end
      member = speech ? member_for_speech(speech) : member_for_hint(hint)
      return nil unless speech || member&.name

      Result.new(speech: speech, member: member, found_by: found_by || (hint[:weak] ? :notice_owner : :chair_named_only))
    end

    private

    attr_reader :question, :speeches, :house, :date

    def moves
      speeches.select { |s| s[:moved_text].present? }
    end

    # The named member's latest move under this debate's own heading, or failing that under
    # another of the bill's, so a move found only by the bill never displaces one found as before.
    def named_move(hint)
      same, other = moves.partition { |s| !s[:other_heading] }
      same.reverse.find { |s| matches_hint?(s, hint) } || other.reverse.find { |s| matches_hint?(s, hint) }
    end

    def recent_unnamed_move
      speeches.reject { |s| s[:other_heading] }.last(UNNAMED_MOVE_WINDOW).reverse.find { |s| s[:moved_text].present? }
    end

    def named_mover
      if (match = question.match(ELECTORATE_HINT))
        { electorate: match[1].strip }
      elsif (match = question.match(MOVED_BY_HINT))
        { name: match[1].strip }
      elsif (match = question.match(NOTICE_OWNER_HINT))
        { name: match[1].strip, weak: true }
      end
    end

    # A surname is enough ("Senator Example" against "Jo Example"), and an electorate needs
    # the speaker's member record, since Hansard's speaker attribute carries only the name.
    def matches_hint?(speech, hint)
      if hint[:name]
        MemberResolver.same_speaker?(speech[:speaker], hint[:name])
      else
        member = member_record(speech[:speaker_gid])
        member.present? && member.constituency.to_s.casecmp?(hint[:electorate])
      end
    end

    def member_for_speech(speech)
      resolved = MemberResolver.resolve(gid: speech[:speaker_gid]) if speech[:speaker_gid].present?
      return resolved if resolved&.member

      MemberResolver.named(speech[:speaker])
    end

    # The chair named someone but their move is not in the excerpt (a deferred division, say),
    # so the name or electorate is looked up directly. A bare surname does not identify a
    # member reliably, so only a full name or an electorate is tried.
    def member_for_hint(hint)
      return nil unless hint
      return nil if hint[:name] && hint[:name].split.size < 2

      resolved = MemberResolver.resolve(name: hint[:name], electorate: hint[:electorate], house: house, date: date)
      resolved&.member ? resolved : nil
    end

    def member_record(gid)
      return nil if gid.blank?

      Member.find_by(gid: gid)
    rescue StandardError
      nil
    end
  end
end
