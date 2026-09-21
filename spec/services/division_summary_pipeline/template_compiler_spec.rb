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

    it "compiles Template 13 with the committee name the extraction supplies" do
      division_data = {
        time: "10:15 AM",
        amount: "majority",
        result: "for",
        mover_title: "Representative",
        mover_name: "Jordan McAllister",
        mover_link: "https://example.com/jordan_mcallister",
        mover_party: "Labor",
        house: "representatives",
        date: "2026-08-19"
      }

      extraction = DivisionSummaryPipeline::ExtractionPayload.new(
        template_id: 13,
        topic: "budget estimates",
        motion_text: "That the matter be referred to the Selection of Bills Committee for inquiry and report.",
        committee_name: "Selection of Bills Committee"
      )

      rendered = described_class.compile(division_data, extraction)
      expect(rendered).to include("to the Selection of Bills Committee for inquiry and report")
      expect(rendered).not_to include("to the  for inquiry")
    end

    def create_downey_member(overrides = {})
      create(:member, {
        person: create(:person),
        first_name: "Alex",
        last_name: "Downey",
        constituency: "Brightwater",
        party: "Liberal",
        house: "representatives",
        entered_house: "2004-10-01",
        left_house: "9999-12-31"
      }.merge(overrides))
    end

    it "uses the database spelling of the censure target in Template 10" do
      create_downey_member
      division_data = {
        time: "10:15 AM",
        amount: "majority",
        result: "against",
        mover_title: "Representative",
        mover_name: "Jordan McAllister",
        mover_link: "https://example.com/jordan_mcallister",
        mover_party: "Labor",
        house: "representatives",
        date: "2026-08-19"
      }
      extraction = DivisionSummaryPipeline::ExtractionPayload.new(
        template_id: 10,
        topic: "ministerial conduct",
        motion_text: "That the House censure the minister.",
        target_name: "Alex Downey"
      )

      rendered = described_class.compile(division_data, extraction)
      expect(rendered).to include("against Alex Downey regarding ministerial conduct")
    end

    describe "template 23 target resolution" do
      let(:division_data) do
        {
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
          date: "2026-08-19"
        }
      end

      def compile_template_23(target_name: nil, target_electorate: nil)
        extraction = DivisionSummaryPipeline::ExtractionPayload.new(
          template_id: 23,
          topic: "Border Processing Amendment Bill 2026",
          motion_text: "That the honourable member for Brightwater be no longer heard.",
          target_name: target_name,
          target_electorate: target_electorate
        )
        described_class.compile(division_data, extraction)
      end

      it "injects the database member's facts for a matched target" do
        create_downey_member

        expect(compile_template_23(target_name: "Alex Downey")).to include(
          "that Brightwater MP [Alex Downey](/people/representatives/brightwater/alex_downey) (Liberal) be no longer heard"
        )
      end

      it "resolves the member from the electorate alone when only the seat is stated" do
        create_downey_member

        expect(compile_template_23(target_electorate: "Brightwater")).to include(
          "that Brightwater MP [Alex Downey](/people/representatives/brightwater/alex_downey) (Liberal) be no longer heard"
        )
      end

      it "quotes the extracted motion text in the motion-text blockquote" do
        create_downey_member

        expect(compile_template_23(target_name: "Alex Downey")).to include(
          "> That the honourable member for Brightwater be no longer heard."
        )
      end

      it "degrades to the plain extracted name when the database has no match" do
        rendered = compile_template_23(target_name: "Alex Downey")

        expect(rendered).to include("that Alex Downey be no longer heard")
        expect(rendered).not_to include("[](")
      end

      it "degrades to the honourable-member phrasing when only an unmatchable electorate is stated" do
        expect(compile_template_23(target_electorate: "Nowhereville")).to include(
          "that the honourable member for Nowhereville be no longer heard"
        )
      end

      it "renders the neutral fallback when nothing about the target is known" do
        expect(compile_template_23).to include("that the member be no longer heard")
      end
    end

    describe "mover resolution and heading protection" do
      it "does not fall back to the division or debate name as the mover name" do
        division_data = {
          time: "10:15 AM",
          amount: "majority",
          result: "for",
          name: "Representative Bills - NDIS Bill 2012; Consideration in Detail",
          house: "representatives"
        }
        extraction = DivisionSummaryPipeline::ExtractionPayload.new(
          template_id: 22,
          topic: "Closure",
          motion_text: "That the question be now put."
        )

        rendered = described_class.compile(division_data, extraction)
        expect(rendered).not_to include("NDIS Bill")
        expect(rendered).to include("introduced by a member")
        expect(rendered).not_to include("[]()")
        expect(rendered).not_to include("() ()")
      end

      it "resolves the mover from speaker claims using MemberResolver when mover_name is not in division data" do
        create_downey_member
        division_data = {
          time: "10:15 AM",
          amount: "majority",
          result: "for",
          house: "representatives",
          date: "2026-08-19"
        }
        extraction = DivisionSummaryPipeline::ExtractionPayload.new(
          template_id: 22,
          topic: "Closure",
          motion_text: "That the question be now put.",
          mover_claims: [
            DivisionSummaryPipeline::ClaimEvidence.new(
              claim: "Closure needed",
              evidence: "closure is needed",
              speaker: "Alex Downey"
            )
          ]
        )

        rendered = described_class.compile(division_data, extraction)
        expect(rendered).to include("introduced by Representative [Alex Downey](/people/representatives/brightwater/alex_downey) (Liberal)")
      end

      it "cleans up empty markdown links and empty parentheses for unlinked movers" do
        division_data = {
          time: "10:15 AM",
          amount: "majority",
          result: "for",
          mover_name: "Sam Taylor",
          house: "representatives"
        }
        extraction = DivisionSummaryPipeline::ExtractionPayload.new(
          template_id: 22,
          topic: "Closure",
          motion_text: "That the question be now put."
        )

        rendered = described_class.compile(division_data, extraction)
        expect(rendered).to include("introduced by Representative Sam Taylor")
        expect(rendered).not_to include("[Sam Taylor]()")
        expect(rendered).not_to include("()")
      end
    end

    # Closure and calling on the business of the day both compile as Template 22, but only a
    # closure is followed by a division on the question it cut short. Calling on the business
    # of the day is used only to end a discussion on a matter of public importance, where
    # there is no question before the Chair to decide.
    describe "Template 22, closure and calling on the business of the day" do
      def closure_data
        {
          time: "04:10 PM",
          amount: "majority",
          result: "passed",
          house: "representatives",
          bill_name: "Fictional Services Bill 2026",
          mover_name: "Fictional Member"
        }
      end

      it "says the chamber then voted on the question after a closure" do
        extraction = DivisionSummaryPipeline::ExtractionPayload.new(
          template_id: 22,
          topic: "the bill",
          motion_text: "That the question be now put."
        )

        rendered = described_class.compile(closure_data, extraction)

        expect(rendered).to include("then voted on the question itself")
      end

      it "says business moved on when the business of the day was called on" do
        extraction = DivisionSummaryPipeline::ExtractionPayload.new(
          template_id: 22,
          topic: "a matter of public importance",
          motion_text: "That the business of the day be called on."
        )

        rendered = described_class.compile(closure_data, extraction)

        expect(rendered).to include("There was no question before the Chair to decide")
        expect(rendered).not_to include("then voted on the question itself")
      end
    end

    # The closing sentence of Template 6 used to be chosen by the bill stage alone, so a defeated
    # division said "the bill has now passed" directly after "which means it was unsuccessful".
    # Both halves of the answer are needed: the stage says what the chamber was asked, the result
    # says whether it agreed (KNOWN_ISSUES.md, KI-1).
    describe "Template 6, reporting the result of the stage and not just the stage" do
      def bill_division_data(result:, extra: {})
        {
          time: "05:00 PM",
          amount: "majority",
          result: result,
          house: "senate",
          date: "2026-06-05",
          bill_name: "Example Bill 2026",
          bill_link: "https://example.com/bills/example-bill-2026",
          mover_name: "Fictional Senator"
        }.merge(extra)
      end

      def bill_extraction(motion_text)
        DivisionSummaryPipeline::ExtractionPayload.new(
          template_id: 6,
          topic: "Example Bill 2026",
          motion_text: motion_text
        )
      end

      let(:third_reading) { bill_extraction("That this bill be now read a third time.") }
      let(:second_reading) { bill_extraction("That this bill be now read a second time.") }

      it "does not say a bill passed when the third reading was defeated" do
        rendered = described_class.compile(bill_division_data(result: "negatived"), third_reading)

        expect(rendered).to include("which means it was unsuccessful.")
        expect(rendered).to include("This means the bill did not pass the Senate.")
        expect(rendered).not_to include("has now passed")
      end

      it "does not say the chamber agreed with the bill when the second reading was defeated" do
        rendered = described_class.compile(bill_division_data(result: "negatived"), second_reading)

        expect(rendered).to include("which means it was unsuccessful.")
        expect(rendered).to include("did not agree to the bill in principle, so it goes no further at this stage")
        expect(rendered).not_to include("agreed with the main idea")
      end

      it "still reports an agreed second reading as agreeing to the bill in principle" do
        rendered = described_class.compile(bill_division_data(result: "passed"), second_reading)

        expect(rendered).to include("which means it was successful.")
        expect(rendered).to include("agreed with the main idea of the bill and can now consider it in greater detail")
      end

      # Where a bill goes next depends on where it started, which TVFY does not record. A bill
      # that came from the other chamber and passes here unamended goes to the Governor-General
      # for assent, not back across (House Guide to Procedures, pp. 87-88), so an unprompted
      # "will go to the House of Representatives" was wrong for that whole class of division.
      it "says only that the bill passed when the originating chamber is unknown" do
        rendered = described_class.compile(bill_division_data(result: "passed"), third_reading)

        expect(rendered).to include("This means the bill has now passed the Senate.")
        expect(rendered).not_to include("House of Representatives")
      end

      it "names the destination chamber when the bill is known to have started in this one" do
        data = bill_division_data(result: "passed", extra: { bill_originating_house: "senate" })

        rendered = described_class.compile(data, third_reading)

        expect(rendered).to include("It started in the Senate, so it now goes to the House of Representatives.")
      end

      it "stays silent on the destination when the bill started in the other chamber" do
        data = bill_division_data(result: "passed", extra: { bill_originating_house: "representatives" })

        rendered = described_class.compile(data, third_reading)

        expect(rendered).to include("This means the bill has now passed the Senate.")
        expect(rendered).not_to include("it now goes to")
      end

      # Section 128's explanation is about the third reading specifically, and it already
      # distinguished a carried bill from a defeated one, so it must survive the change above.
      it "keeps the Section 128 explanation for a defeated Constitution Alteration third reading" do
        data = bill_division_data(result: "negatived",
                                  extra: { bill_name: "Constitution Alteration (Fictional Reform) 2026" })

        rendered = described_class.compile(data, third_reading)

        expect(rendered).to include("requires it to pass by an absolute majority")
        expect(rendered).to include("The bill did not pass this stage.")
        expect(rendered).not_to include("has now passed")
      end
    end

    describe "Template 28, a question that part of a bill stand as printed" do
      let(:division_data) do
        {
          time: "03:45 PM",
          amount: "majority",
          house: "senate",
          bill_name: "Migration Amendment Bill 2026",
          mover_title: "Senator",
          mover_name: "Fictional Senator",
          mover_link: "https://example.com/fictional-senator",
          mover_party: "Independent"
        }
      end

      let(:extraction) do
        DivisionSummaryPipeline::ExtractionPayload.new(
          template_id: 28,
          topic: "clause 4",
          motion_text: "That clause 4 stand as printed."
        )
      end

      # The Senate puts an amendment to omit part of a bill as "That the [unit] stand as
      # printed", so defeating the question is what omits the unit. The reported vote
      # direction has to stay true to the question, because that is what the aye and no
      # counts beside the summary are counts of, and the consequence is stated separately.
      it "reports a defeated question as a vote against it, and says the part was omitted" do
        rendered = described_class.compile(division_data.merge(result: "negatived"), extraction)

        expect(rendered).to include("voted against a question that part of the Migration Amendment Bill 2026 stand as printed")
        expect(rendered).to include("defeating the question is what omitted that part of the bill")
        expect(rendered).to include("the text of the bill has changed accordingly")
      end

      it "reports a carried question as a vote for it, and says the part was kept" do
        rendered = described_class.compile(division_data.merge(result: "passed"), extraction)

        expect(rendered).to include("voted for a question that part of the Migration Amendment Bill 2026 stand as printed")
        expect(rendered).to include("kept that part of the bill unchanged and defeated the amendment to omit it")
      end

      it "leaves the effect clause out of every other template" do
        in_committee = DivisionSummaryPipeline::ExtractionPayload.new(
          template_id: 3,
          topic: "Migration Amendment Bill 2026",
          motion_text: "That clause 4 stand as printed."
        )

        rendered = described_class.compile(division_data.merge(result: "negatived"), in_committee)

        expect(rendered).not_to include("stand as printed, defeating the question")
      end
    end

    describe "constitutional and parliamentary procedures" do
      def quorum_division_data(date:)
        {
          time: "11:00 AM",
          house: "representatives",
          date: date,
          aye_votes: 14,
          no_votes: 10,
          result: "passed",
          mover_name: "Fictional Member"
        }
      end

      let(:quorum_extraction) do
        DivisionSummaryPipeline::ExtractionPayload.new(
          template_id: 15,
          topic: "a scheduling motion",
          motion_text: "That the House take the next item of business."
        )
      end

      it "explains the absolute majority a Constitution Alteration bill needs at the third reading" do
        division_data = {
          time: "05:00 PM",
          amount: "majority",
          result: "passed",
          bill_name: "Constitution Alteration (Fictional Reform) 2026",
          house: "representatives",
          mover_name: "Fictional Member"
        }
        extraction = DivisionSummaryPipeline::ExtractionPayload.new(
          template_id: 6,
          topic: "Constitution Alteration (Fictional Reform) 2026",
          motion_text: "That this bill be now read a third time."
        )

        rendered = described_class.compile(division_data, extraction)

        expect(rendered).to include("through its third reading")
        expect(rendered).to include("requires it to pass by an absolute majority, meaning a majority of all the members of the chamber and not just of those who voted")
        expect(rendered).to include("The House always rings the bells for a division at this stage, even when nobody opposes the bill")
      end

      # The same requirement, recorded differently: the Senate records the names of senators
      # voting on such a third reading even when no division is called.
      it "describes the Senate's way of recording that majority rather than the House's" do
        division_data = {
          time: "05:00 PM",
          amount: "majority",
          result: "passed",
          bill_name: "Constitution Alteration (Fictional Reform) 2026",
          house: "senate",
          mover_name: "Fictional Senator"
        }
        extraction = DivisionSummaryPipeline::ExtractionPayload.new(
          template_id: 6,
          topic: "Constitution Alteration (Fictional Reform) 2026",
          motion_text: "That this bill be now read a third time."
        )

        rendered = described_class.compile(division_data, extraction)

        expect(rendered).to include("records the names of senators voting on the third reading of such a bill even when no division is called")
        expect(rendered).not_to include("rings the bells")
      end

      # Section 23's own words are "shall pass in the negative", which reads to anyone outside
      # parliament as though the question passed. The Senate's own guide says "the question is
      # lost", and that is what a reader needs.
      it "says an equally divided Senate question was lost, not that it passed in the negative" do
        division_data = {
          time: "02:15 PM",
          house: "senate",
          aye_votes: 36,
          no_votes: 36,
          result: "negatived",
          tied: true,
          mover_name: "Fictional Senator"
        }
        extraction = DivisionSummaryPipeline::ExtractionPayload.new(
          template_id: 15,
          topic: "Energy Policy",
          motion_text: "That the Senate records its concern."
        )

        rendered = described_class.compile(division_data, extraction)

        expect(rendered).to include("an equally divided Senate")
        expect(rendered).to include("the question was lost")
        expect(rendered).to include("has no casting vote")
        expect(rendered).not_to include("passed in the negative")
      end

      # A House tie is resolved by the casting vote, and the Chair is not always the Speaker
      # (a Deputy Speaker or Acting Speaker has the same casting vote), so the summary names
      # the office rather than the person.
      it "attributes a House tie to the casting vote of the occupant of the Chair" do
        division_data = {
          time: "02:15 PM",
          house: "representatives",
          aye_votes: 75,
          no_votes: 75,
          result: "negatived",
          tied: true,
          mover_name: "Fictional Member"
        }
        extraction = DivisionSummaryPipeline::ExtractionPayload.new(
          template_id: 15,
          topic: "Energy Policy",
          motion_text: "That the House records its concern."
        )

        rendered = described_class.compile(division_data, extraction)

        expect(rendered).to include("an equally divided House of Representatives")
        expect(rendered).to include("decided by the casting vote of the occupant of the Chair")
        expect(rendered).to include("Section 40 of the Constitution")
      end

      # House S.O. 58: a division showing fewer than a quorum voting makes no decision. The
      # quorum is one fifth of the House, so it moved from 30 to 31 when the House grew to 151.
      it "flags a want of quorum against the 30-member threshold for a pre-2019 division" do
        rendered = described_class.compile(quorum_division_data(date: "2015-03-04"), quorum_extraction)

        expect(rendered).to include("which means it was not decided, because fewer than a quorum of members voted.")
        expect(rendered).to include("only 24 members voted, fewer than the quorum of 30")
        expect(rendered).to include("Under House Standing Order 58")
      end

      it "flags a want of quorum against the 31-member threshold once the House grew to 151" do
        rendered = described_class.compile(quorum_division_data(date: "2021-03-04"), quorum_extraction)

        expect(rendered).to include("fewer than the quorum of 31")
      end

      it "says nothing about a quorum when the date is unknown" do
        rendered = described_class.compile(quorum_division_data(date: nil), quorum_extraction)

        expect(rendered).not_to include("quorum")
      end

      # The Guides to Senate Procedure set out no rule voiding a Senate division for want of a
      # quorum, so the pipeline does not invent one, and senators may simply abstain by
      # staying away.
      it "never raises a quorum notice for a Senate division" do
        data = quorum_division_data(date: "2021-03-04").merge(house: "senate")

        expect(described_class.compile(data, quorum_extraction)).not_to include("quorum")
      end

      it "reports a conscience vote when party whips are free" do
        division_data = {
          time: "04:30 PM",
          house: "representatives",
          amount: "majority",
          result: "passed",
          free_vote: true,
          mover_name: "Alex Smith"
        }
        extraction = DivisionSummaryPipeline::ExtractionPayload.new(
          template_id: 15,
          topic: "Marriage Amendment Bill",
          motion_text: "That this bill be agreed to."
        )

        rendered = described_class.compile(division_data, extraction)
        expect(rendered).to include("This was a conscience vote (free vote). Members were not bound by party whips, so no party rebellions are recorded.")
      end
    end

    describe "new procedural templates (24 to 27)" do
      it "compiles Template 24 (Suspension of a Member) with resolved target" do
        create_downey_member
        division_data = {
          time: "02:30 PM",
          amount: "majority",
          result: "passed",
          mover_name: "Tony Burke",
          mover_party: "Labor",
          house: "representatives",
          date: "2026-08-19"
        }
        extraction = DivisionSummaryPipeline::ExtractionPayload.new(
          template_id: 24,
          topic: "Disorder",
          motion_text: "That the member for Brightwater be suspended from the service of the House.",
          target_electorate: "Brightwater"
        )

        rendered = described_class.compile(division_data, extraction)
        expect(rendered).to start_with("**Jargon Explainer:** *This disciplinary vote suspends a member")
        expect(rendered).to include("that Brightwater MP [Alex Downey](/people/representatives/brightwater/alex_downey) (Liberal) be suspended from the service of the House of Representatives")
      end

      it "compiles Template 25 (Dissent from Ruling)" do
        division_data = {
          time: "11:45 AM",
          amount: "majority",
          result: "negatived",
          mover_name: "Paul Fletcher",
          mover_party: "Liberal",
          house: "representatives"
        }
        extraction = DivisionSummaryPipeline::ExtractionPayload.new(
          template_id: 25,
          topic: "a Speaker's ruling on relevance",
          motion_text: "That the Speaker's ruling be dissented from.",
          mover_claims: [
            DivisionSummaryPipeline::ClaimEvidence.new(
              claim: "The Minister's answer was not directly relevant",
              evidence: "not directly relevant",
              speaker: "Paul Fletcher"
            )
          ]
        )

        rendered = described_class.compile(division_data, extraction)
        expect(rendered).to start_with("**Jargon Explainer:** *A motion of dissent challenges a formal procedural ruling")
        expect(rendered).to include("to dissent from a ruling of the Chair regarding a Speaker's ruling on relevance, which means it was unsuccessful.")
      end

      it "compiles Template 26 (Adjournment)" do
        division_data = {
          time: "10:30 PM",
          amount: "majority",
          result: "passed",
          mover_name: "Tony Burke",
          mover_party: "Labor",
          house: "representatives"
        }
        extraction = DivisionSummaryPipeline::ExtractionPayload.new(
          template_id: 26,
          topic: "Adjournment",
          motion_text: "That the House do now adjourn."
        )

        rendered = described_class.compile(division_data, extraction)
        expect(rendered).to start_with("**Jargon Explainer:** *At a set time each sitting day the chair proposes that the chamber do now adjourn.")
        expect(rendered).to include("that the House of Representatives do now adjourn, which means it was successful.")
      end

      it "compiles Template 27 (Taking Note)" do
        division_data = {
          time: "04:15 PM",
          amount: "majority",
          result: "passed",
          mover_name: "Penny Wong",
          mover_party: "Labor",
          house: "senate"
        }
        extraction = DivisionSummaryPipeline::ExtractionPayload.new(
          template_id: 27,
          topic: "a ministerial statement on foreign affairs",
          motion_text: "That the Senate take note of the document.",
          mover_claims: [
            DivisionSummaryPipeline::ClaimEvidence.new(
              claim: "Enable debate on foreign affairs",
              evidence: "enable debate",
              speaker: "Penny Wong"
            )
          ]
        )

        rendered = described_class.compile(division_data, extraction)
        expect(rendered).to start_with("**Jargon Explainer:** *A motion to \"take note\" is the device")
        expect(rendered).to include("to take note of a ministerial statement on foreign affairs, which means it was successful.")
      end
    end

    # Template 7 covers the whole message family, and the forms in it do not all mean the same
    # thing or even point the same way (KNOWN_ISSUES.md, KI-2). Senate Guide No. 18: "if a
    # majority votes against the motion, the effect is that the amendments are insisted on".
    describe "Template 7, the forms a message question takes" do
      def message_division(result:, house: "senate")
        {
          time: "09:20 PM",
          amount: "majority",
          result: result,
          mover_title: house == "senate" ? "Senator" : "Representative",
          mover_name: "Fictional Member",
          mover_link: "https://example.com/m",
          mover_party: "Labor",
          bill_name: "Example Bill 2026",
          bill_link: "https://example.com/bill",
          house: house
        }
      end

      def message_extraction(motion_text)
        DivisionSummaryPipeline::ExtractionPayload.new(
          template_id: 7, topic: "Example Bill 2026", motion_text: motion_text
        )
      end

      it "says a defeated 'does not insist' is what insists on the amendments" do
        rendered = described_class.compile(
          message_division(result: "negatived"),
          message_extraction("That the committee does not insist on its amendments to which the House of " \
                             "Representatives has disagreed.")
        )

        expect(rendered).to include("that the Senate not insist on its own amendments")
        expect(rendered).to include("defeating it is what insists on the amendments")
        expect(rendered).not_to include("to agree to the amendments the House of Representatives made")
      end

      it "attributes the amendments to this chamber, not the other one, on an insist question" do
        rendered = described_class.compile(
          message_division(result: "passed"),
          message_extraction("That the committee insists on its amendments.")
        )

        expect(rendered).to include("that the Senate insist on its own amendments")
        expect(rendered).to include("the Senate kept its own amendments")
      end

      it "flips an equally divided 'does not insist' the other way, as the Senate guide does" do
        data = message_division(result: "negatived").merge(aye_votes: 36, no_votes: 36, tied: true)
        rendered = described_class.compile(
          data,
          message_extraction("That the committee does not insist on its amendments.")
        )

        expect(rendered).to include("the amendments are not insisted on")
        expect(rendered).to include("chair of committees makes a statement")
      end

      it "still describes a plain agree question as agreeing to the other chamber's amendments" do
        rendered = described_class.compile(
          message_division(result: "passed", house: "representatives"),
          message_extraction("That the amendments made by the Senate be agreed to.")
        )

        expect(rendered).to include("to agree to the amendments the Senate made")
        expect(rendered).to include("accepted the Senate's changes to the bill")
      end

      it "says a carried disagree rejects them and returns the bill with reasons" do
        rendered = described_class.compile(
          message_division(result: "passed", house: "representatives"),
          message_extraction("That the amendments be disagreed to.")
        )

        expect(rendered).to include("to disagree to the amendments the Senate made")
        expect(rendered).to include("rejected the Senate's changes")
      end

      it "explains section 53 when the question is about requests rather than amendments" do
        rendered = described_class.compile(
          message_division(result: "passed"),
          message_extraction("That the requests be made to the House of Representatives.")
        )

        expect(rendered).to include("Section 53 of the Constitution")
        expect(rendered).to include("requests for amendments")
      end
    end

    # House Guide pp. 40-41: calling on the business of the day exists only to curtail a
    # discussion on a matter of public importance, and is provided "because there is no
    # question before the Chair during an MPI". Describing it as a closure that forces an
    # immediate vote contradicted the trailing clause in the same paragraph (KI-3).
    describe "Template 22, the three questions that arrive as a closure" do
      def closure_division(result:)
        {
          time: "03:40 PM", amount: "majority", result: result,
          mover_title: "Representative", mover_name: "Fictional Member",
          mover_link: "https://example.com/m", mover_party: "Labor",
          house: "representatives", bill_name: "Example Bill 2026", bill_link: "https://example.com/bill"
        }
      end

      it "does not describe calling on the business of the day as forcing an immediate vote" do
        extraction = DivisionSummaryPipeline::ExtractionPayload.new(
          template_id: 22, topic: "cost of living", motion_text: "That the business of the day be called on."
        )

        rendered = described_class.compile(closure_division(result: "passed"), extraction)

        expect(rendered).to include("ends a discussion on a matter of public importance")
        expect(rendered).to include("to call on the business of the day and end the discussion")
        expect(rendered).to include("There was no question before the Chair to decide")
        expect(rendered).not_to include("put the question immediately")
        expect(rendered).not_to include("which is put to a separate vote straight afterwards")
      end

      it "describes the ballot closure used in the election of a Speaker" do
        extraction = DivisionSummaryPipeline::ExtractionPayload.new(
          template_id: 22, topic: "election of the Speaker", motion_text: "That the ballot be taken now."
        )

        rendered = described_class.compile(closure_division(result: "passed"), extraction)

        expect(rendered).to include("to end the debate and take the ballot immediately")
        expect(rendered).to include("then proceeded to the ballot")
      end

      it "says the debate continued when an ordinary closure was defeated" do
        extraction = DivisionSummaryPipeline::ExtractionPayload.new(
          template_id: 22, topic: "Example Bill 2026", motion_text: "That the question be now put."
        )

        rendered = described_class.compile(closure_division(result: "negatived"), extraction)

        expect(rendered).to include("The debate continued.")
        expect(rendered).not_to include("then voted on the question itself")
      end
    end

    # Template 15 is the fallback for every question no rule matched, so its sentence was
    # printed over forms it is simply wrong about, approval of a legislative instrument among
    # them (KI-4).
    describe "Template 15, the fallback's claim about legal effect" do
      def general_division
        {
          time: "03:40 PM", amount: "majority", result: "passed",
          mover_title: "Representative", mover_name: "Fictional Member",
          mover_link: "https://example.com/m", mover_party: "Labor", house: "representatives"
        }
      end

      it "says nothing about legal effect when the motion is not a declaratory one" do
        extraction = DivisionSummaryPipeline::ExtractionPayload.new(
          template_id: 15, topic: "an agreement",
          motion_text: "That the House approves the form of agreement set out in the schedule."
        )

        rendered = described_class.compile(general_division, extraction)

        expect(rendered).not_to include("has no legal effect")
      end

      it "still says so when the motion records an opinion" do
        extraction = DivisionSummaryPipeline::ExtractionPayload.new(
          template_id: 15, topic: "housing",
          motion_text: "That the House notes the state of housing supply."
        )

        rendered = described_class.compile(general_division, extraction)

        expect(rendered).to include("records an opinion of the House of Representatives and has no legal effect")
      end
    end

    # A suspension states its own purpose in the words after "as would prevent" (House Guide
    # p. 2). The stock "to debate an urgent matter" was a guess, and stuttered when the topic
    # was itself about urgency (KI-10).
    describe "Template 17, the purpose a suspension states for itself" do
      def suspension_division
        {
          time: "11:00 AM", amount: "majority", result: "passed",
          mover_title: "Representative", mover_name: "Fictional Member",
          mover_link: "https://example.com/m", mover_party: "Labor", house: "representatives"
        }
      end

      it "takes the purpose from the motion's own words" do
        extraction = DivisionSummaryPipeline::ExtractionPayload.new(
          template_id: 17, topic: "an urgent matter",
          motion_text: "That so much of the standing orders be suspended as would prevent the member for " \
                       "Fairview moving a motion relating to aged care funding forthwith."
        )

        rendered = described_class.compile(suspension_division, extraction)

        expect(rendered).to include("prevent the member for Fairview moving a motion relating to aged care funding forthwith")
        expect(rendered).not_to include("urgent matter regarding an urgent matter")
        expect(rendered).not_to include("to allow the House of Representatives to debate an urgent matter")
      end

      it "falls back to the topic when the motion does not use the usual form" do
        extraction = DivisionSummaryPipeline::ExtractionPayload.new(
          template_id: 17, topic: "aged care funding",
          motion_text: "That standing order 65 be suspended for this sitting."
        )

        rendered = described_class.compile(suspension_division, extraction)

        expect(rendered).to include("(Labor) regarding aged care funding. The vote was successful.")
      end

      # KI-5: a suspension moved without notice needs an absolute majority, and the question
      # alone does not say how it was moved.
      it "flags a suspension carried on fewer votes than an absolute majority" do
        extraction = DivisionSummaryPipeline::ExtractionPayload.new(
          template_id: 17, topic: "aged care funding",
          motion_text: "That so much of the standing orders be suspended as would prevent a motion being moved."
        )
        data = suspension_division.merge(aye_votes: 70, no_votes: 68, date: "2024-06-05")

        rendered = described_class.compile(data, extraction)

        expect(rendered).to include("needs an absolute majority")
        expect(rendered).to include("at least 76")
        expect(rendered).to include("the question alone does not record which it was")
      end

      it "says nothing about an absolute majority when the ayes clear it anyway" do
        extraction = DivisionSummaryPipeline::ExtractionPayload.new(
          template_id: 17, topic: "aged care funding",
          motion_text: "That so much of the standing orders be suspended as would prevent a motion being moved."
        )
        data = suspension_division.merge(aye_votes: 84, no_votes: 54, date: "2024-06-05")

        rendered = described_class.compile(data, extraction)

        expect(rendered).not_to include("Notice: a motion to suspend standing orders moved without notice")
      end
    end

    # House S.O. 94(d) sets escalating periods, not "the remainder of the sitting", and the
    # Senate suspends from the sitting rather than the service (KI-7).
    describe "Template 24, suspension periods and the two chambers' wording" do
      def suspension_of_member(house)
        {
          time: "02:30 PM", amount: "majority", result: "passed",
          mover_title: house == "senate" ? "Senator" : "Representative",
          mover_name: "Fictional Member", mover_link: "https://example.com/m",
          mover_party: "Labor", house: house
        }
      end

      it "gives the House's escalating periods rather than the remainder of the sitting" do
        extraction = DivisionSummaryPipeline::ExtractionPayload.new(
          template_id: 24, topic: "Disorder",
          motion_text: "That the member be suspended from the service of the House.",
          target_name: "Fictional Member"
        )

        rendered = described_class.compile(suspension_of_member("representatives"), extraction)

        expect(rendered).to include("24 hours on a first occasion")
        expect(rendered).to include("seven consecutive sittings on a third or later occasion")
        expect(rendered).to include("be suspended from the service of the House of Representatives")
        expect(rendered).not_to include("excluded for the remainder of the sitting")
      end

      it "uses the Senate's form of words and does not assert its suspension periods" do
        extraction = DivisionSummaryPipeline::ExtractionPayload.new(
          template_id: 24, topic: "Disorder",
          motion_text: "That the senator be suspended from the sitting of the Senate.",
          target_name: "Fictional Senator"
        )

        rendered = described_class.compile(suspension_of_member("senate"), extraction)

        expect(rendered).to include("be suspended from the sitting of the Senate")
        expect(rendered).to include("standing order 204")
        expect(rendered).not_to include("24 hours on a first occasion")
      end
    end

    # House S.O.s 31 and 32(a): at the scheduled time the Speaker proposes the adjournment
    # with nobody moving it, so there is no mover to name (KI-12).
    describe "Template 26, an adjournment with no mover" do
      it "leaves the mover out rather than naming 'a member'" do
        extraction = DivisionSummaryPipeline::ExtractionPayload.new(
          template_id: 26, topic: "Adjournment", motion_text: "That the House do now adjourn."
        )

        rendered = described_class.compile(
          { time: "08:00 PM", amount: "majority", result: "negatived", house: "representatives" },
          extraction
        )

        expect(rendered).to include("voted against a procedural motion that the House of Representatives do now adjourn")
        expect(rendered).not_to include("introduced by")
        expect(rendered).to include("returned to the business it was part way through")
      end
    end

    # The cosmetic tidying passes used to run over the whole compiled document, including the
    # blockquoted motion text, so they silently edited quoted Hansard.
    describe "verbatim quoted text" do
      it "leaves runs of spaces inside the quoted motion alone" do
        extraction = DivisionSummaryPipeline::ExtractionPayload.new(
          template_id: 15, topic: "housing",
          motion_text: "That the House notes:    (a) the first thing; and    (b) the second thing."
        )

        rendered = described_class.compile(
          { time: "03:40 PM", amount: "majority", result: "passed", house: "representatives",
            mover_name: "Fictional Member" },
          extraction
        )

        expect(rendered).to include("> That the House notes:    (a) the first thing; and    (b) the second thing.")
      end

      it "does not collapse a doubled 'the' that a member actually said" do
        extraction = DivisionSummaryPipeline::ExtractionPayload.new(
          template_id: 15, topic: "housing",
          motion_text: "That the House notes the the minister misspoke."
        )

        rendered = described_class.compile(
          { time: "03:40 PM", amount: "majority", result: "passed", house: "representatives",
            mover_name: "Fictional Member" },
          extraction
        )

        expect(rendered).to include("> That the House notes the the minister misspoke.")
      end
    end

    # An equally divided division had no majority either way, and in the House the casting vote
    # that settles it is not in the aye and no counts.
    describe "an equally divided division" do
      it "does not say a tied House division was voted for or against" do
        division_data = {
          time: "02:15 PM", house: "representatives", aye_votes: 75, no_votes: 75,
          result: "negatived", tied: true, mover_name: "Fictional Member"
        }
        extraction = DivisionSummaryPipeline::ExtractionPayload.new(
          template_id: 15, topic: "Energy Policy", motion_text: "That the House records its concern."
        )

        rendered = described_class.compile(division_data, extraction)

        expect(rendered).to include("an equally divided House of Representatives voted on a")
        expect(rendered).to include("not decided by the division figures, which were equal")
        expect(rendered).to include("do not record which way that casting vote went")
      end
    end
  end
end
