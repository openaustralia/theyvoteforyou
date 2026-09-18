# frozen_string_literal: true

require "spec_helper"

describe DivisionSummaryPipeline::TemplateCompiler do
  describe ".compile" do
    it "compiles Template 22 (Closure of Debate) deterministically" do
      division_data = {
        time: "10:15 AM",
        amount: "majority",
        result: "for",
        mover_title: "Representative",
        mover_name: "Jordan McAllister",
        mover_link: "https://theyvoteforyou.org.au/people/representatives/brightwater/jordan_mcallister",
        mover_party: "Labor",
        bill_name: "Border Processing Amendment Bill 2026",
        bill_link: "https://theyvoteforyou.org.au/bills/border-processing-amendment-bill-2026",
        house: "representatives"
      }

      extraction = DivisionSummaryPipeline::ExtractionPayload.new(
        template_id: 22,
        topic: "Border Processing Amendment Bill 2026",
        motion_text: "That the question be now put."
      )

      rendered = described_class.compile(division_data, extraction)
      expect(rendered).to start_with("**Jargon Explainer:**")
      expect(rendered).not_to include("### 22.")
      expect(rendered).to include("At 10:15 AM, a majority voted for a procedural motion introduced by Representative [Jordan McAllister]")
      expect(rendered).to include("Nobody voted against their party on this occasion.")
      expect(rendered).to include("> That the question be now put.")
    end

    it "compiles Template 2 (Second Reading Amendment) with declines_second_reading" do
      division_data = {
        time: "12:39 PM",
        amount: "large majority",
        result: "against",
        mover_title: "Independent MP",
        mover_name: "Priya Nakamura",
        mover_link: "https://www.theyvoteforyou.org.au/people/representatives/fairview/priya_nakamura",
        mover_party: "Independent",
        bill_name: "Consumer Data Right Amendment (Portability) Bill 2026",
        bill_link: "https://theyvoteforyou.org.au/bills/consumer-data-right-amendment-portability-bill-2026",
        house: "representatives"
      }

      extraction = DivisionSummaryPipeline::ExtractionPayload.new(
        template_id: 2,
        topic: "Consumer Data Right Amendment (Portability) Bill 2026",
        declines_second_reading: true,
        motion_text: "That all words after 'whilst' be omitted...",
        mover_claims: [
          DivisionSummaryPipeline::ClaimEvidence.new(
            claim: "Highlighting that small retailers are not yet ready to comply",
            evidence: "small retailers are not yet ready to comply",
            speaker: "Priya Nakamura"
          )
        ]
      )

      rendered = described_class.compile(division_data, extraction)
      expect(rendered).to start_with("**Bill Timeline:**")
      expect(rendered).not_to include("### 2.")
      expect(rendered).to include("Because the amendment sought to decline the bill a second reading, a vote for it was in effect a vote against the bill proceeding.")
      expect(rendered).to include("At 12:39 PM, Independent MP Priya Nakamura states that this amendment will:")
      expect(rendered).to include("> * Highlighting that small retailers are not yet ready to comply.")
    end

    it "compiles the digest section with the exact TEMPLATES.md wording when a Bills Digest is found" do
      division_data = {
        time: "12:39 PM",
        amount: "large majority",
        result: "against",
        mover_title: "Independent MP",
        mover_name: "Priya Nakamura",
        mover_link: "https://example.com/priya_nakamura",
        mover_party: "Independent",
        bill_name: "Example Bill 2026",
        bill_link: "https://example.com/bills/example-bill-2026",
        house: "representatives",
        digest_key_points: ["The bill establishes a scheme.", "The bill starts on 1 July 2026."],
        digest_link: "https://www.aph.gov.au/Parliamentary_Business/Bills_Legislation/bd/example"
      }

      extraction = DivisionSummaryPipeline::ExtractionPayload.new(
        template_id: 6,
        topic: "Example Bill 2026",
        motion_text: "That this bill be now read a second time.",
        declines_second_reading: nil
      )

      rendered = described_class.compile(division_data, extraction)
      expect(rendered).to include("According to the [Bill Digest](https://www.aph.gov.au/Parliamentary_Business/Bills_Legislation/bd/example):")
      expect(rendered).to include("> * The bill establishes a scheme.")
    end

    it "falls back to the exact no-digest wording when no Bills Digest is available" do
      division_data = {
        time: "12:39 PM",
        amount: "majority",
        result: "for",
        mover_title: "Senator",
        mover_name: "Alex Smith",
        mover_link: "https://example.com/alex_smith",
        mover_party: "Labor",
        bill_name: "Example Bill 2026",
        bill_link: "https://example.com/bill",
        house: "senate"
      }

      extraction = DivisionSummaryPipeline::ExtractionPayload.new(
        template_id: 1,
        topic: "Example Bill 2026",
        motion_text: "That this bill be now read a first time."
      )

      rendered = described_class.compile(division_data, extraction)
      expect(rendered).to include("### About the Bill\n\n> No Bill Digest found.")
    end

    it "compiles Template 22 with a link to the follow-up division when one is supplied" do
      division_data = {
        time: "10:15 AM",
        amount: "majority",
        result: "for",
        mover_title: "Representative",
        mover_name: "Jordan McAllister",
        mover_link: "https://example.com/jordan_mcallister",
        mover_party: "Labor",
        bill_name: "Border Processing Amendment Bill 2026",
        bill_link: "https://example.com/bill",
        house: "representatives",
        followup_link: "https://theyvoteforyou.org.au/divisions/representatives/2026-08-19/3"
      }

      extraction = DivisionSummaryPipeline::ExtractionPayload.new(
        template_id: 22,
        topic: "Border Processing Amendment Bill 2026",
        motion_text: "That the question be now put."
      )

      rendered = described_class.compile(division_data, extraction)
      expect(rendered).to include("The House of Representatives then voted on the question itself, which you can read about [here](https://theyvoteforyou.org.au/divisions/representatives/2026-08-19/3).")
    end

    it "collapses duplicated definite articles in compiled output" do
      division_data = {
        time: "10:15 AM",
        amount: "majority",
        result: "for",
        mover_title: "Senator",
        mover_name: "Alex Smith",
        mover_link: "https://example.com/alex_smith",
        mover_party: "Labor",
        committee_name: "the Selection of Bills Committee",
        topic: "budget estimates",
        house: "senate"
      }

      extraction = DivisionSummaryPipeline::ExtractionPayload.new(
        template_id: 13,
        topic: "budget estimates",
        motion_text: "That the matter be referred to the committee."
      )

      rendered = described_class.compile(division_data, extraction)
      expect(rendered).to include("to the Selection of Bills Committee for inquiry and report")
      expect(rendered).not_to include("the the")
    end
  end
end

