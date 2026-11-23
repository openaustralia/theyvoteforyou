# frozen_string_literal: true

require "htmlentities"

module DivisionSummaryPipeline
  # TextNormaliser handles cleaning, whitespace collapsing, entity decoding,
  # and character normalisation for Hansard text and provenance assertion.
  #
  # Keep #normalise_for_matching separate from the other two and out of anything published.
  # It exists so stage 4 compares words rather than typography (Hansard and a model's
  # transcription of it differ in quote and dash characters, wrapping and case), and it is
  # lossy by design: text put through it is no longer fit to show anyone.
  class TextNormaliser
    # Decodes the full HTML entity table (named and numeric), matching the Python prototype's
    # html.unescape. The same gem Division already uses for entity decoding. Not frozen: the
    # gem lazily memoises its decoder instance on the first #decode call (@decoder ||= ...),
    # so freezing this constant makes every decode raise FrozenError.
    ENTITY_DECODER = HTMLEntities.new

    # Strips XML markup while preserving line breaks and unescaping entities.
    def self.strip_xml_markup(raw_xml)
      return "" if raw_xml.blank?

      cleaned = raw_xml.dup
      cleaned.gsub!(/<\?[^>]+\?>/, "")
      cleaned.gsub!(/<!DOCTYPE[^>]+>/, "")

      # Replace paragraph and speech breaks with newlines
      cleaned.gsub!(%r{</p\s*>}i, "\n")
      cleaned.gsub!(%r{<br\s*/?>}i, "\n")
      cleaned.gsub!(%r{</speech\s*>}i, "\n\n")

      # Remove remaining tags
      cleaned.gsub!(/<[^>]+>/, " ")

      # Decode HTML entities
      cleaned = ENTITY_DECODER.decode(cleaned)

      # Normalise spaces and non-breaking spaces while keeping line structure
      cleaned.gsub!("\u00A0", " ")
      lines = cleaned.split("\n").map do |line|
        line.gsub(/[ \t]+/, " ").strip
      end.reject(&:empty?)

      lines.join("\n")
    end

    # Cleans and normalises plain text whitespace.
    def self.clean_text(text)
      return "" if text.blank?

      cleaned = ENTITY_DECODER.decode(text.to_s)
      cleaned.gsub!("\r\n", "\n")
      cleaned.gsub!("\u00A0", " ")
      cleaned.gsub!(/[ \t]+/, " ")
      cleaned.gsub!(/\n\s*\n+/, "\n\n")
      cleaned.strip
    end

    # Normalises text specifically for robust substring provenance matching:
    # - Decodes HTML entities (e.g. &amp;, &#160;, &quot;)
    # - Replaces curly quotes and apostrophe look-alikes with straight quotes
    # - Replaces the dash family with hyphens, and an ellipsis character with three full stops
    # - Drops invisible characters (soft hyphens, zero-width spaces)
    # - Collapses all whitespace into a single space, then drops the space either side of
    #   punctuation, since Hansard and a model disagree most about exactly that: "to:(i)" in the
    #   source against "to: (i)" in the quote, or the reverse
    # - Drops a full stop stuck to the start of a word ("is .anti-competitive"), a typesetting
    #   artefact in recent Hansard XML that no model reproduces
    # - Converts to lowercase
    #
    # Every step changes spacing, punctuation or typography only and is applied to both sides,
    # so the words themselves still have to match in order, one after another.
    INVISIBLE_CHARACTERS = /[\u00AD\u200B-\u200D\u2060\uFEFF]/
    DASHES = /[\u2010-\u2015\u2212]/
    SPACE_BESIDE_PUNCTUATION = / ?([^[:alnum:][:space:]]) ?/
    STRAY_FULL_STOP = /(?<=\s)\.(?=[[:alpha:]])/

    def self.normalise_for_matching(text)
      return "" if text.blank?

      s = ENTITY_DECODER.decode(text.to_s)
      s.tr!("“”", "\"\"")
      s.tr!("‘’ʼ′", "''''")
      s.gsub!(DASHES, "-")
      s.gsub!("…", "...")
      s.gsub!(INVISIBLE_CHARACTERS, "")
      s.gsub!("\u00A0", " ")
      s.gsub!(/\s+/, " ")
      s.gsub!(STRAY_FULL_STOP, "")
      s.gsub!(SPACE_BESIDE_PUNCTUATION, "\\1")
      s.strip.downcase
    end
  end
end
