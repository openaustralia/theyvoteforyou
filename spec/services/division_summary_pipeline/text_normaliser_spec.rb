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
      expect(normalised).to eq("\"the minister's 'decision'-immediate action\"")
    end
  end
end
