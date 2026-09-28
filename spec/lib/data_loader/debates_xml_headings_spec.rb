# frozen_string_literal: true

require "spec_helper"
require "nokogiri"

describe DataLoader::DebatesXml do
  describe "#speeches_under_minor_heading" do
    it "collects the speeches of every section with that heading, ignoring case and spacing" do
      doc = Nokogiri::XML(<<~XML)
        <debates>
          <minor-heading id="h1">Fair Pricing Bill 2026;  Second Reading</minor-heading>
          <speech id="s1" speakername="Robin Carrow"><p>First.</p></speech>
          <minor-heading id="h2">Another Bill 2026</minor-heading>
          <speech id="s2" speakername="Sam Okafor"><p>Other.</p></speech>
          <minor-heading id="h3">FAIR PRICING BILL 2026; SECOND READING</minor-heading>
          <speech id="s3" speakername="Jess Harlow"><p>Second.</p></speech>
        </debates>
      XML

      speeches = described_class.new(doc, "representatives").speeches_under_minor_heading("Fair Pricing Bill 2026; Second Reading")

      expect(speeches.map { |speech| speech.attr(:speakername) }).to eq(["Robin Carrow", "Jess Harlow"])
    end
  end
end
