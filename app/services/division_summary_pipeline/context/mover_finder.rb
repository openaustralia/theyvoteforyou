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
  # earlier in the debate, such as an amendment moved before a second reading question. The
  # chair putting other questions in between does not count against that, since a run of
  # questions separates nothing: under a guillotine the second reading question comes after the
  # chair has put each second reading amendment in turn. Even then the move must be one the
  # question could be putting: a question on amendments is never decided by "That this bill be
  # now read a second time" (KI-43, where exactly that credited the
  # Greens' circulated amendments to the minister who moved the second reading).
  #
  # A move found under another of the bill's headings (EarlierDebate's :other_heading) never
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
    # put, counting members' speeches only: the move itself, perhaps a seconder, and one more.
    UNNAMED_MOVE_WINDOW = 3

    # A question on amendments, and terms that could be what it puts: an amendment in any of its
    # forms ("Omit ...", "Leave out ... insert ...", "At the end of the motion, add ...", "That all
    # words after "That" be omitted with a view to substituting ...", "(1) Schedule 1, item 4,
    # page 3, omit the item, substitute:", "(2) Schedule 1, item 66, ..., to be opposed."), or a
    # motion about amendments, such as the House's "That the amendment be agreed to" on a Senate
    # message. What they rule out is a reading, a suspension or an adjournment.
    AMENDMENT_QUESTION = /\bamendments?\b|\bsheets?\b|\bitems?\b|\bstand\s+as\s+printed\b/i
    AMENDMENT_TERMS = /\b(?:omit|omitted|leave\s+out|insert|substitute|substituting|add|to\s+be\s+opposed|
                          amendments?|requests?)\b/ix
    READING = /\bread\s+a\s+(first|second|third)\s+time\b/i

    ELECTORATE_HINT = /moved\s+by\s+the\s+(?:honourable\s+|hon\.?\s+)?member\s+for\s+([A-Z][\w'’-]*(?:[ -][A-Z][\w'’-]*)*)/
    MOVED_BY_HINT = /moved\s+by\s+(?:Senator|Mr|Mrs|Ms|Miss|Dr)\s+(?:the\s+Hon\.?\s+)?([A-Z][\w'’-]*(?:\s+[A-Z][\w'’-]*)*)/
    NOTICE_OWNER_HINT = /in\s+the\s+name\s+of\s+(?:Senator|Mr|Mrs|Ms|Miss|Dr)\s+(?:the\s+Hon\.?\s+)?([A-Z][\w'’-]*(?:\s+[A-Z][\w'’-]*)*)/

    # question: the sentence putting the question. putting: all the chair's words putting it
    # (ChairStatement#putting_text), where the chair often names the mover in a sentence of its own.
    # circulated: the chair says the amendments being put were circulated, so nobody moved them in
    # the chamber and a recent move is someone else's (Circulation).
    def self.find(question:, speeches:, house: nil, date: nil, putting: nil, circulated: false)
      new(question: question, putting: putting, speeches: speeches, house: house, date: date, circulated: circulated).find
    end

    def initialize(question:, putting:, speeches:, house:, date:, circulated:)
      @question = question.to_s
      @putting = putting.presence || @question
      @speeches = Array(speeches)
      @house = house
      @date = date
      @circulated = circulated
    end

    def find
      hint = named_mover
      speech = named_move(hint) if hint
      found_by = (hint[:weak] ? :notice_owner : :chair_named) if hint && speech
      if speech.nil? && (hint.nil? || hint[:weak]) && !@circulated
        speech = recent_unnamed_move
        found_by = :recent_move if speech
      end
      member = speech ? member_for_speech(speech) : member_for_hint(hint)
      return nil unless speech || member&.name

      Result.new(speech: speech, member: member, found_by: found_by || (hint[:weak] ? :notice_owner : :chair_named_only))
    end

    private

    attr_reader :question, :putting, :speeches, :house, :date

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
      members = speeches.reject { |s| s[:other_heading] || chair_statement?(s) }
      members.last(UNNAMED_MOVE_WINDOW).reverse.find { |s| s[:moved_text].present? && fits_question?(s[:moved_text]) }
    end

    def chair_statement?(speech)
      return false if speech[:moved_text].present?

      paragraphs = speech[:paragraphs]
      plain = paragraphs ? paragraphs.select { |p| p[:kind] == :prose }.pluck(:text).join("\n\n") : speech[:text]
      DataLoader::DivisionXml.chair_statement_text?(plain)
    end

    # Whether these terms could be what the question puts: amendments for a question on
    # amendments, and the same reading for a reading. Any other question is left open.
    def fits_question?(moved_text)
      return moved_text.match?(AMENDMENT_TERMS) if question.match?(AMENDMENT_QUESTION)

      reading = question[READING, 1]
      reading.nil? || moved_text[READING, 1].to_s.casecmp?(reading)
    end

    def named_mover
      if (match = putting.match(ELECTORATE_HINT))
        { electorate: match[1].strip }
      elsif (match = putting.match(MOVED_BY_HINT))
        { name: match[1].strip }
      elsif (match = putting.match(NOTICE_OWNER_HINT))
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
