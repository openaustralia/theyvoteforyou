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
    # explanatory memorandum relating to the bill and move:". A match is only a candidate:
    # #moved_text also needs motion paragraphs after it, or "that ..." in the same sentence, so
    # "I move on to my next point" moves nothing.
    MOVE_PATTERN = /\bI(?:,\s*and\s+also\s+on\s+behalf\s+of\s+[^,]+,)?\s+(?:(?:present|table)\s+[^.:;]{1,200}?\s+and\s+)?(?:now\s+|formally\s+|therefore\s+|also\s+|accordingly\s+)?move\b/i

    # Where an inline motion starts in the rest of an "I move" paragraph ("I move: That ...").
    INLINE_MOTION_START = /\A[\s:,-]*(?=that\b)/i

    # The line Hansard puts before a speech incorporated by leave. Its wording varies: "The
    # speech", "The speeches", "The incorporated speech" (the House), and "The speech es" where
    # one notice is split across three tags, sometimes after a leftover "() ():" of the
    # speaker's name. Reports, documents and messages are introduced the same way ("The report
    # read as follows"), but they are not the member's words, so only a speech counts.
    INCORPORATION_NOTICE = /\A(?:\(\)\s*:?\s*)*The\s+(?:incorporated\s+)?speech\s*(?:es)?\s+read\s+as\s+follows/i

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
    # - :prose, everything else, including a speech incorporated by leave.
    #
    # :move and :motion blocks carry `move:`, counting the moves in the speech from 0, since a
    # speech can move more than one thing. An inline "I move: That the question be now put." is
    # split into "I move:" and "That the question be now put.", both exact text of the paragraph.
    def paragraphs(speech)
      elements = speech.element_children.to_a
      roles = move_roles(elements)

      elements.each_with_index.flat_map do |element, index|
        role = roles[index]
        text = paragraph_text(element)
        next [] if text.empty?
        next split_inline_move(text, role[:move]) if role[:kind] == :inline_move

        text.split("\n\n").map { |block| role[:kind] == :prose ? { text: block, kind: :prose } : role.merge(text: block) }
      end
    end

    # The name as TVFY records it where the speaker is a known member, otherwise as Hansard
    # printed it.
    def speaker_name(speech)
      member = Member.find_by(gid: speech.attr(:speakerid))
      member ? member.name : speech.attr(:speakername)
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
    # a move when motion paragraphs follow it, or it carries the motion inline, so "I move on to
    # my next point" is prose.
    #
    # An incorporated speech is found first and never searched for a move. A minister's second
    # reading speech in the Senate is often the House speech, opening "I move that this Bill be
    # now read a second time.", and read as a move it made the whole speech the terms moved
    # (KI-39). The minister's real move comes before they seek leave to incorporate it.
    def move_roles(elements)
      notices, incorporated = incorporation(elements)
      set_apart = notices | incorporated
      roles = Array.new(elements.size) { |i| notices.include?(i) ? { kind: :quotation } : { kind: :prose } }
      moves = 0
      elements.each_with_index do |element, index|
        next if roles[index][:kind] != :prose || set_apart.include?(index) || !element.text.match?(MOVE_PATTERN)

        motion = motion_indices_after(elements, index, set_apart)
        if motion.any?
          roles[index] = { kind: :move, move: moves }
          motion.each { |i| roles[i] = { kind: :motion, move: moves } }
        elsif inline_motion_start(paragraph_text(element))
          roles[index] = { kind: :inline_move, move: moves }
        else
          next
        end
        moves += 1
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

    def split_inline_move(text, move)
      start = inline_motion_start(text)
      [{ text: text[0...start].rstrip, kind: :move, move: move }, { text: text[start..], kind: :motion, move: move }]
        .reject { |block| block[:text].empty? }
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
