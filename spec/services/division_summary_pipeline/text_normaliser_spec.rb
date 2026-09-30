# frozen_string_literal: true

require "spec_helper"

describe DivisionSummaryPipeline::TextNormaliser do
  describe ".strip_xml_markup" do
    it "removes XML and HTML tags while preserving line structure" do
      xml = "<p>First line</p><p>Second line with <span style=\"font-weight:bold;\">bold</span> text</p>"
      expect(described_class.strip_xml_markup(xml)).to eq("First line\nSecond line with bold text")
    end

    it "decodes named and numeric HTML entities, not just the basic five" do
      xml = "<p>Prices &amp; costs &mdash; &pound;50 &#8212; done</p>"
      stripped = described_class.strip_xml_markup(xml)
      expect(stripped).to eq("Prices & costs \u2014 £50 \u2014 done")
    end

    it "returns empty string for nil or blank input" do
      expect(described_class.strip_xml_markup(nil)).to eq("")
      expect(described_class.strip_xml_markup("")).to eq("")
    end
  end

  describe ".clean_text" do
    it "collapses excessive whitespace and normalises newlines" do
      text = "Word1    Word2\r\n\r\n\r\nWord3"
      expect(described_class.clean_text(text)).to eq("Word1 Word2\n\nWord3")
    end
  end

  describe ".normalise_for_matching" do
    it "normalises curly quotes, dashes, whitespace and case" do
      input = "“The Minister’s ‘Decision’\u2014Immediate action”"
      normalised = described_class.normalise_for_matching(input)
      expect(normalised).to eq("\"the minister's'decision'-immediate action\"")
    end

    it "decodes HTML entities so entity representations match plain text" do
      input = "Trade &amp; Industry &mdash; &quot;Urgent&#160;Reform&quot;"
      normalised = described_class.normalise_for_matching(input)
      expect(normalised).to eq("trade&industry-\"urgent reform\"")
    end

    # Nokogiri used to join Hansard paragraphs with no space ("the Senate:(a) notes"), and
    # models quote them with one; either way round, the words are the same.
    it "ignores whether there is a space beside punctuation" do
      expect(described_class.normalise_for_matching("the Senate:(a) notes:(i) the cost"))
        .to eq(described_class.normalise_for_matching("the Senate: (a) notes: (i) the cost"))
    end

    it "keeps the spaces between words, so run-together words do not match" do
      expect(described_class.normalise_for_matching("the cost burden"))
        .not_to eq(described_class.normalise_for_matching("the costburden"))
    end

    it "drops the stray full stop recent Hansard XML sometimes puts at the start of a word" do
      expect(described_class.normalise_for_matching("Commission is\u00A0\u00A0\u00A0.anti-competitive"))
        .to eq(described_class.normalise_for_matching("Commission is anti-competitive"))
    end

    it "drops soft hyphens and zero-width spaces and treats every dash as a hyphen" do
      expect(described_class.normalise_for_matching("needs\u00ADbased co\u2011operation\u200B"))
        .to eq("needsbased co-operation")
    end
  end
end
