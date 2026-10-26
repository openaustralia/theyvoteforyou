# frozen_string_literal: true

module DataLoader
  # Reads one ParlParse <speech> element the way the AI division summary pipeline needs it
  # (app/services/division_summary_pipeline/ARCHITECTURE.md): who spoke, what they said with
  # its paragraph breaks intact, and the terms of any motion they moved. The nightly loader
  # does not use this; DivisionXml#motion keeps its own PHP-compatible formatting.
  #
  # Paragraph breaks matter because Nokogiri's #text joins sibling paragraphs with nothing in
  # between, so "...the Senate:</p><p>(a) notes..." reads "the Senate:(a) notes". A model then
  # quotes it with a normal space, and a quote that was said word for word fails the
  # pipeline's verbatim check.
  #
  # Current ParlParse XML marks a motion's terms as <p class="italic"> rather than the
  # <p pwmotiontext="..."> attribute older files (and DivisionXml#pwmotiontexts) use. Italic
  # also marks speeches incorporated by leave, and everything else Hansard sets apart from what
  # the member said: words they quote or read out (another person's statement, a letter, a
  # report, a petition), amendments the chair reads, and editorial notes. So a paragraph only
  # counts as motion text when it follows "I move" in the same speech, and any other italic
  # paragraph outside an incorporated speech is a quotation, never the member's own words
  # (KNOWN_ISSUES.md KI-38).
  module SpeechText
    # Elements that start a new block of text. Older files nest a motion's clauses in
    # <dl><dt>(a)</dt><dd>...</dd></dl> rather than one <p> per clause.
    BLOCK_ELEMENTS = %w[p dl dt dd ul ol li table tr br div blockquote].freeze
    BLOCK_BREAK = "\u0001"
    BLOCK_BREAKS = /\u0001+/

    # A typesetting artefact in recent Hansard XML: a run of non-breaking spaces and a full stop
    # in front of a hyphenated word ("operation of&#xA0;&#xA0;&#xA0;.needs-based funding"). It is
    # not something anyone said, and left in it reaches the published motion text as
    # "is .anti-competitive".
    STRAY_FULL_STOP = /\u00A0{2,}\.(?=[[:alpha:]])/

    # What is left at the start of a speech when the member's name and electorate are taken out
    # of the markup: "():  I rise to speak to the bill". Nobody said it either.
    EMPTY_SPEAKER_PREFIX = /\A\(\)\s*:\s*/

    # "I move", allowing the adverbs members put in the middle ("I formally move") and the longer
    # Senate forms: "I, and also on behalf of Senator Example, move:", and presenting or tabling
    # something first, as in "I present the bill and move:", "I present the report of the Example
    # Committee, together with accompanying documents and move:" and "I table a revised
    # explanatory memorandum relating to the bill and move:". A match is only a candidate: the
    # paragraph must also end by introducing motion paragraphs after it (#introduces_motion?), or
    # carry "That ..." inline, so "I move on to my next point" moves nothing.
    MOVE_PATTERN = /\bI(?:,\s*and\s+also\s+on\s+behalf\s+of\s+[^,]+,)?\s+(?:(?:present|table)\s+[^.:;]{1,200}?\s+and\s+)?(?:now\s+|formally\s+|therefore\s+|also\s+|accordingly\s+)?move\b/i

    # Between two sentences. Needs a capital after the full stop, so "Bill No. 2:" is not split.
    SENTENCE_BREAK = /(?<=[.!?])\s+(?=[[:upper:]])/

    # Where an inline motion starts in the rest of an "I move" paragraph ("I move: That ...").
    INLINE_MOTION_START = /\A[\s:,-]*(?=that\b)/i

    # The line Hansard puts before a speech incorporated by leave. Its wording varies: "The
    # speech", "The speeches", "The incorporated speech" (the House), and "The speech es" where
    # one notice is split across three tags, sometimes after a leftover "() ():" of the
    # speaker's name. Reports, documents and messages are introduced the same way ("The report
    # read as follows"), but they are not the member's words, so only a speech counts.
    INCORPORATION_NOTICE = /\A(?:\(\)\s*:?\s*)*The\s+(?:incorporated\s+)?speech\s*(?:es)?\s+read\s+as\s+follows/i

    # What Hansard records of the chamber inside a member's speech, as a paragraph of its own: the
    # chamber's leave, interjections, the clock, and the questions it decided. Plain type, so they
    # read as the member's own sentences, and one could have been quoted as "Senator Example said:
    # Leave not granted." (KI-57). The forms found in House and Senate Hansard
    # from May to September 2026, with or without Hansard's closing dash.
    RECORD = /\A(?:
      leave\s+(?:not\s+)?granted(?:;\s*debate\s+adjourned)? |
      leave\s+is\s+granted\s+for\s+one\s+minute |
      \(time\s+expired\) |
      (?:an?\s+)?(?:(?:honourable|opposition|government|crossbench)\s+)?(?:senators?|members?)\s+interjecting |
      (?:senator|mr|mrs|ms|miss|dr)\s+[\w'’-]+(?:\s+[\w'’-]+){0,2}\s+interjecting |
      (?:original\s+)?question(?:,\s+as\s+amended,)?\s+
        (?:agreed\s+to|negatived|resolved\s+in\s+the\s+(?:affirmative|negative))
        (?:,\s+with\s+an\s+absolute\s+majority)? |
      bills?(?:,\s+as\s+amended,)?\s+(?:read\s+a\s+(?:first|second|third)\s+time|agreed\s+to) |
      debate\s+adjourned |
      order!
    )[\s.—–-]*\z/xi

    module_function

    def context_speech(speech)
      {
        id: speech.attr(:id),
        speaker: speaker_name(speech),
        speaker_gid: speech.attr(:speakerid),
        time: speech.attr(:time),
        text: paragraph_text(speech),
        paragraphs: paragraphs(speech),
        moved_text: moved_text(speech)
      }
    end

    # Every block of the speech in order, each with what it is, so the pipeline can quote a
    # member's own words without ever mistaking the motion, or someone else's words, for them:
    #
    # - :move, the paragraph that says "I move" (or the part of it before an inline motion),
    # - :motion, the terms moved,
    # - :quotation, text Hansard set apart in italic that is neither a motion nor part of an
    #   incorporated speech, and the notice introducing an incorporated speech, and
    # - :record, Hansard recording the chamber in a paragraph of its own (RECORD), and
    # - :prose, everything else, including a speech incorporated by leave, whose blocks also carry
    #   `incorporated: true`: they are the member's words for the record, but were not delivered
    #   orally in the chamber (Senate Guide No. 10).
    #
    # :move and :motion blocks carry `move:`, counting the moves in the speech from 0, since a
    # speech can move more than one thing. An inline "I move: That the question be now put." is
    # split into "I move:" and "That the question be now put.", both exact text of the paragraph.
    # An inline motion ends with its sentence (see #inline_move_blocks).
    def paragraphs(speech)
      elements = speech.element_children.to_a
      roles = move_roles(elements)

      elements.each_with_index.flat_map do |element, index|
        role = roles[index]
        text = paragraph_text(element)
        next [] if text.empty?
        next role[:blocks] if role[:kind] == :inline_move

        text.split("\n\n").map do |block|
          role[:kind] == :prose && block.match?(RECORD) ? { text: block, kind: :record } : { text: block }.merge(role)
        end
      end
    end

    # The name as TVFY records it where the speaker is a known member, otherwise as Hansard
    # printed it.
    def speaker_name(speech)
      member = Member.find_by(gid: speech.attr(:speakerid))
      member ? member.name : speech.attr(:speakername)
    end

    # The speech's text without its italic paragraphs: what the speaker said, apart from what
    # Hansard set apart from it, such as the amendments a chair reads out as the question is put.
    def plain_text(speech)
      speech.element_children.reject { |element| italic?(element) }
            .map { |element| paragraph_text(element) }.reject(&:empty?).join("\n\n")
    end

    # The element's text with one blank line between blocks and single spaces inside them.
    def paragraph_text(node)
      raw_block_text(node).split(BLOCK_BREAKS)
                          .map { |block| block.gsub(STRAY_FULL_STOP, " ").gsub(/[[:space:]]+/, " ").strip.sub(EMPTY_SPEAKER_PREFIX, "") }
                          .reject(&:empty?)
                          .join("\n\n")
    end

    # The terms of the motion or amendment this speech moved last, or nil if it moved none: the
    # motion paragraphs that follow an "I move" paragraph, or failing those, the rest of that
    # sentence when it reads "I move: That ..." inline, as older files and short procedural
    # motions do.
    def moved_text(speech)
      blocks = paragraphs(speech).select { |block| block[:kind] == :motion }
      return nil if blocks.empty?

      last_move = blocks.last[:move]
      blocks.select { |block| block[:move] == last_move }.pluck(:text).join("\n\n")
    end

    # What each element of a speech is (see #paragraphs). An "I move" paragraph only counts as
    # a move when it introduces motion paragraphs that follow it (see #introduces_motion?), or it
    # carries the motion inline, so "I move on to my next point" is prose.
    #
    # An incorporated speech is found first and never searched for a move. A minister's second
    # reading speech in the Senate is often the House speech, opening "I move that this Bill be
    # now read a second time.", and read as a move it made the whole speech the terms moved
    # (KI-39). The minister's real move comes before they seek leave to incorporate it.
    def move_roles(elements)
      notices, incorporated = incorporation(elements)
      set_apart = notices | incorporated
      roles = Array.new(elements.size) do |i|
        if notices.include?(i) then { kind: :quotation }
        elsif incorporated.include?(i) then { kind: :prose, incorporated: true }
        else { kind: :prose }
        end
      end
      moves = 0
      elements.each_with_index do |element, index|
        # An italic paragraph is words Hansard sets apart as quoted, so its "I move" is not the member's.
        next if roles[index][:kind] != :prose || set_apart.include?(index) || italic?(element) || !element.text.match?(MOVE_PATTERN)

        motion = motion_indices_after(elements, index, set_apart)
        if motion.any? && introduces_motion?(element)
          roles[index] = { kind: :move, move: moves }
          motion.each { |i| roles[i] = { kind: :motion, move: moves } }
          moves += 1
        elsif (blocks = inline_move_blocks(paragraph_text(element), moves))
          roles[index] = { kind: :inline_move, blocks: blocks }
          moves += blocks.count { |block| block[:kind] == :motion }
        end
      end
      elements.each_index do |i|
        roles[i] = { kind: :quotation } if roles[i][:kind] == :prose && incorporated.exclude?(i) && italic?(elements[i])
      end
      roles
    end

    # The indices of the notices introducing an incorporated speech, and of the speech itself:
    # everything after a notice up to the first plain paragraph, where the member speaks again
    # ("I seek leave to continue my remarks later.") or Hansard records what happened next
    # ("Debate adjourned."). Only a plain <p> ends it, because the Senate's files set lists inside
    # an incorporated speech in plain <ul> elements. In the House an incorporated speech is plain
    # throughout, so nothing after its notice is marked, and it reads as prose as it always did.
    def incorporation(elements)
      notices = Set.new
      incorporated = Set.new
      inside = false
      elements.each_with_index do |element, index|
        text = paragraph_text(element)
        if text.match?(INCORPORATION_NOTICE)
          notices << index
          inside = true
        elsif inside && element.name == "p" && !italic?(element) && !text.empty?
          inside = false
        elsif inside
          incorporated << index
        end
      end
      [notices, incorporated]
    end

    # Whether an "I move" paragraph introduces the terms in the paragraphs after it: its last sentence
    # is the move and ends with a colon ("I move the second reading amendment on sheet 9001:", or
    # "...which is why I move the amendment circulated in my name. I move:"). A paragraph that only
    # contains the words earlier on, such as "I move on to my next point... The minister said:", can sit
    # just in front of an italic quotation, and is not a move. In the 1,461 moves introduced by a
    # paragraph of their own in 66 sitting days from 1 May to 22 October 2026, every one passed this test.
    def introduces_motion?(element)
      text = paragraph_text(element)
      text.end_with?(":") && text.split(SENTENCE_BREAK).last.match?(MOVE_PATTERN)
    end

    def motion_indices_after(elements, index, set_apart)
      following = ((index + 1)...elements.size).drop_while { |i| elements[i].text.strip.empty? }
      following.take_while { |i| set_apart.exclude?(i) && (motion_element?(elements[i]) || elements[i].text.strip.empty?) }
               .reject { |i| elements[i].text.strip.empty? }
    end

    # The offset in an "I move" paragraph where an inline motion begins, or nil.
    def inline_motion_start(text)
      move = text.match(MOVE_PATTERN)
      return nil unless move

      gap = text[move.end(0)..].match(INLINE_MOTION_START)
      gap && (move.end(0) + gap[0].size)
    end

    # The blocks of an "I move" paragraph that carries its motions inline, or nil if it carries
    # none. Each motion ends with its sentence: what follows is the member's own words, or
    # another inline move, as in "I move that ... immediately. I move that the question be now
    # put." on 30 March 2026, so moves are counted on from first_move.
    def inline_move_blocks(text, first_move)
      blocks = []
      move = first_move
      rest = text
      while (start = inline_motion_start(rest))
        motion, after = rest[start..].split(SENTENCE_BREAK, 2)
        blocks << { text: rest[0...start].rstrip, kind: :move, move: move } << { text: motion, kind: :motion, move: move }
        move += 1
        rest = after.to_s
      end
      return nil if blocks.empty?

      blocks << { text: rest, kind: :prose }
      blocks.reject { |block| block[:text].empty? }
    end

    def motion_element?(element)
      return true if element.attr(:pwmotiontext).present?
      return true if %w[dl blockquote].include?(element.name)

      italic?(element)
    end

    def italic?(element)
      element.name == "p" && element.attr(:class).to_s.split.include?("italic")
    end

    def raw_block_text(node)
      node.children.map do |child|
        if child.text?
          child.text
        elsif BLOCK_ELEMENTS.include?(child.name)
          "#{BLOCK_BREAK}#{raw_block_text(child)}#{BLOCK_BREAK}"
        else
          raw_block_text(child)
        end
      end.join
    end
  end
end
