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
  # also marks incorporated speeches and procedural notes such as "Leave granted.", so a
  # paragraph only counts as motion text when it follows "I move" in the same speech.
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

    # "I move", allowing the adverbs members put in the middle ("I formally move") and the two
    # longer Senate forms, "I, and also on behalf of Senator Example, move:" and "I present the
    # bill and move:". A match is
    # only a candidate: #moved_text also needs motion paragraphs after it, or "that ..." in the
    # same sentence, so "I move on to my next point" moves nothing.
    MOVE_PATTERN = /\bI(?:,\s*and\s+also\s+on\s+behalf\s+of\s+[^,]+,)?\s+(?:present\s+the\s+bill\s+and\s+)?(?:now\s+|formally\s+|therefore\s+|also\s+|accordingly\s+)?move\b/i

    module_function

    def context_speech(speech)
      {
        id: speech.attr(:id),
        speaker: speaker_name(speech),
        speaker_gid: speech.attr(:speakerid),
        time: speech.attr(:time),
        text: paragraph_text(speech),
        moved_text: moved_text(speech)
      }
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

    # The terms of the motion or amendment this speech moved, or nil if it moved none. Takes
    # the motion paragraphs that follow the last "I move" paragraph, or failing those, the rest
    # of that sentence when it reads "I move: That ..." inline, as older files and short
    # procedural motions do.
    def moved_text(speech)
      elements = speech.element_children.to_a
      start = elements.rindex { |element| element.text.match?(MOVE_PATTERN) }
      return nil unless start

      following = elements[(start + 1)..].drop_while { |element| element.text.strip.empty? }
      motion = following.take_while { |element| motion_element?(element) || element.text.strip.empty? }
      text = motion.map { |element| paragraph_text(element) }.reject(&:empty?).join("\n\n")
      return text if text.present?

      inline = elements[start].text.split(MOVE_PATTERN, 2).last.to_s.sub(/\A[\s:,-]+/, "").strip
      inline if inline.match?(/\Athat\b/i)
    end

    def motion_element?(element)
      return true if element.attr(:pwmotiontext).present?
      return true if %w[dl blockquote].include?(element.name)

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
