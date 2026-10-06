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
    # - Replaces curly quotes with straight quotes
    # - Replaces em/en dashes with hyphens
    # - Collapses all whitespace into a single space
    # - Converts to lowercase
    def self.normalise_for_matching(text)
      return "" if text.blank?

      s = ENTITY_DECODER.decode(text.to_s)
      s.tr!("“”", "\"\"")
      s.tr!("‘’", "''")
      s.gsub!(/[\u2014\u2013]/, "-")
      s.gsub!("\u00A0", " ")
      s.gsub!(/\s+/, " ")
      s.strip.downcase
    end
  end
end
