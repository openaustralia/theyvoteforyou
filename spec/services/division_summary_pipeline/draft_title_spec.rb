# frozen_string_literal: true

require "spec_helper"

describe DivisionSummaryPipeline::DraftTitle do
  describe ".for" do
    it "replaces the stage the minor heading ends with by the template's procedure" do
      title = described_class.for(heading: "Bills &#8212; Example Bill 2026; Second Reading", template_id: 2)

      expect(title).to eq("Bills - Example Bill 2026; Second Reading Amendment")
    end

    it "keeps a minor heading that has no stage part to drop" do
      title = described_class.for(heading: "Business &#8212; Rearrangement", template_id: 17)

      expect(title).to eq("Business - Rearrangement; Suspension of Standing Orders")
    end

    it "keeps every bill a minor heading lists and drops only its last part" do
      heading = "Bills &#8212; First Example Bill 2026, Second Example Bill 2026; Second Reading"

      expect(described_class.for(heading: heading, template_id: 2))
        .to eq("Bills - First Example Bill 2026, Second Example Bill 2026; Second Reading Amendment")
    end

    # Each reading has its own template, so the title names the reading the division decided
    # even under a heading still saying "Second Reading" over a third reading.
    it "names the reading from the template rather than the heading" do
      heading = "Bills &#8212; Example Bill 2026; Second Reading"

      expect(described_class.for(heading: heading, template_id: 6)).to eq("Bills - Example Bill 2026; Third Reading")
      expect(described_class.for(heading: heading, template_id: 29)).to eq("Bills - Example Bill 2026; Second Reading")
    end

    it "gives the hyphenated heading alone when there is no template to name" do
      heading = "Bills &#8212; Example Bill 2026; Second Reading"

      expect(described_class.for(heading: heading)).to eq("Bills - Example Bill 2026")
      expect(described_class.for(heading: heading, template_id: 99)).to eq("Bills - Example Bill 2026")
    end

    # KI-48: the loader title-cases headings for PHP compatibility, which
    # turns "NDIS" into "Ndis".
    it "prints a bill's title in the heading as the bills table records it" do
      heading = "Bills &#8212; Example Scheme Amendment (Securing the Esp for Future Generations) Bill 2026; Second Reading"
      title = described_class.for(heading: heading, template_id: 29,
                                  bill_titles: ["Example Scheme Amendment (Securing the ESP for Future Generations) Bill 2026"])

      expect(title).to eq("Bills - Example Scheme Amendment (Securing the ESP for Future Generations) Bill 2026; Second Reading")
    end

    it "uses the fallback when the heading is blank" do
      expect(described_class.for(heading: "", template_id: 15, fallback: "Division 4")).to eq("Division 4; General Motion")
      expect(described_class.for(heading: nil, fallback: "Division 4")).to eq("Division 4")
    end

    it "names the procedure alone when there is neither a heading nor a fallback" do
      expect(described_class.for(heading: nil, template_id: 26)).to eq("Adjournment")
    end

    describe "em dashes" do
      it "writes a joining em dash as a hyphen, whether encoded or not" do
        expect(described_class.for(heading: "Bills \u2014 Example Bill 2026; Second Reading", template_id: 2))
          .to eq("Bills - Example Bill 2026; Second Reading Amendment")
      end

      it "writes an em dash inside a minor heading as a hyphen too" do
        title = described_class.for(heading: "Bills &#8212; Example Bill 2026 &#8212; Schedule 1; Second Reading",
                                    template_id: 2)

        expect(title).to eq("Bills - Example Bill 2026 - Schedule 1; Second Reading Amendment")
      end

      # DivisionSummarizer passes the Division's name as the fallback, and Division#name decodes
      # the loader's "&#8212;" back into an em dash, so the fallback is hyphenated too.
      it "writes an em dash in the fallback as a hyphen" do
        title = described_class.for(heading: "", template_id: 15, fallback: "Motions \u2014 Example Matter")

        expect(title).not_to include("\u2014")
        expect(title).not_to include("&#8212;")
      end

      it "never leaves one in any title built from a heading" do
        headings = ["Bills &#8212; Example Bill 2026; Second Reading", "Business \u2014 Rearrangement",
                    "Motions &#8212; Example &#8212; Matter", "&#8212; Example"]
        titles = headings.product([nil, *DivisionSummaryPipeline::TemplateCatalogue::IDS]).map do |heading, id|
          described_class.for(heading: heading, template_id: id)
        end

        expect(titles.grep(/\u2014|&#8212;/)).to be_empty
      end
    end
  end
end
