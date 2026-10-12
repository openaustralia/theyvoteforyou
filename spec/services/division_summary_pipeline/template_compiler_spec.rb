# frozen_string_literal: true

require "spec_helper"

# Stage 5 compiles from the interpretation and the verified Hansard evidence, never from anything
# the model wrote. compile_summary (spec/support/division_summary_helpers.rb) builds both from
# plain strings, so each example states only the evidence it is about.
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

      rendered = compile_summary(division_data, template_id: 22, motion_text: "That the question be now put.")
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

      rendered = compile_summary(
        division_data,
        template_id: 2,
        declines_second_reading: true,
        motion_text: "That all words after 'whilst' be omitted...",
        explanations: ["small retailers are not yet ready to comply"]
      )
      expect(rendered).to start_with("**Bill Timeline:**")
      expect(rendered).not_to include("### 2.")
      expect(rendered).to include("Because the amendment sought to refuse the bill a second reading, a vote for it was in effect a vote against the bill proceeding.")
      # The explanation carries the time of the speech it was taken from, not the division's.
      expect(rendered).to include("At 1:27 PM, Independent MP Priya Nakamura said:\n\n> small retailers are not yet ready to comply")
    end

    it "compiles the digest section with the original design's exact wording when a Bills Digest is found" do
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

      rendered = compile_summary(division_data, template_id: 29, motion_text: "That this bill be now read a second time.")
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

      rendered = compile_summary(division_data, template_id: 1, motion_text: "That this bill be now read a first time.")
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

      rendered = compile_summary(division_data, template_id: 22, motion_text: "That the question be now put.")
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
        house: "senate"
      }

      rendered = compile_summary(
        division_data,
        template_id: 13,
        motion_text: "That the matter be referred to the committee.",
        facts: { committee_name: "the Selection of Bills Committee" }
      )
      expect(rendered).to include("to the Selection of Bills Committee for inquiry and report")
      expect(rendered).not_to include("the the")
    end

    it "compiles Template 13 with the committee name Hansard supplies" do
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

      rendered = compile_summary(
        division_data,
        template_id: 13,
        motion_text: "That the matter be referred to the Selection of Bills Committee for inquiry and report.",
        facts: { committee_name: "Selection of Bills Committee" }
      )
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

      rendered = compile_summary(
        division_data,
        template_id: 10,
        motion_text: "That the House censure the minister.",
        facts: { target_name: "Alex Downey" }
      )
      expect(rendered).to include("against Alex Downey, which means it was unsuccessful.")
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
        compile_summary(
          division_data,
          template_id: 23,
          motion_text: "That the honourable member for Brightwater be no longer heard.",
          facts: { target_name: target_name, target_electorate: target_electorate }.compact
        )
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

      it "quotes the motion text in the motion-text blockquote" do
        create_downey_member

        expect(compile_template_23(target_name: "Alex Downey")).to include(
          "> That the honourable member for Brightwater be no longer heard."
        )
      end

      it "degrades to the plain name Hansard gives when the database has no match" do
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

        rendered = compile_summary(division_data, template_id: 22, motion_text: "That the question be now put.")
        expect(rendered).not_to include("NDIS Bill")
        expect(rendered).to include("a procedural motion to end the debate")
        expect(rendered).not_to include("introduced by")
        expect(rendered).not_to include("[]()")
        expect(rendered).not_to include("() ()")
      end

      # This example used to resolve the mover from the speaker of the model's claims. That path
      # was removed on purpose: the mover now comes only from the division data or from the
      # member Stage 1 found by rule (Evidence#mover), so the speaker of an explanation passage
      # is never promoted to mover, even when it matches a member in the database.
      it "does not take the mover from the speaker of an explanation passage" do
        create_downey_member
        division_data = {
          time: "10:15 AM",
          amount: "majority",
          result: "for",
          house: "representatives",
          date: "2026-08-19"
        }
        interpretation, evidence = summary_inputs(template_id: 22, motion_text: "That the question be now put.")
        evidence = evidence.with(explanations: [summary_excerpt("Closure is needed.", speaker: "Alex Downey", found_by: :model)])

        rendered = described_class.compile(division_data, interpretation, evidence)
        expect(rendered).not_to include("introduced by")
        expect(rendered).not_to include("[Alex Downey]")
      end

      it "links the mover Stage 1 resolved against the database" do
        create_downey_member
        division_data = {
          time: "10:15 AM",
          amount: "majority",
          result: "for",
          house: "representatives",
          date: "2026-08-19"
        }
        mover = DivisionSummaryPipeline::MemberResolver.resolve(
          name: "Alex Downey",
          house: "representatives",
          date: "2026-08-19"
        )

        rendered = compile_summary(
          division_data,
          template_id: 22,
          motion_text: "That the question be now put.",
          mover: mover
        )
        expect(rendered).to include("introduced by [Alex Downey](/people/representatives/brightwater/alex_downey) MP (Liberal)")
      end

      it "cleans up empty markdown links and empty parentheses for unlinked movers" do
        division_data = {
          time: "10:15 AM",
          amount: "majority",
          result: "for",
          mover_name: "Sam Taylor",
          house: "representatives"
        }

        rendered = compile_summary(division_data, template_id: 22, motion_text: "That the question be now put.")
        expect(rendered).to include("introduced by Sam Taylor MP")
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
        rendered = compile_summary(closure_data, template_id: 22, motion_text: "That the question be now put.")

        expect(rendered).to include("then voted on the question itself")
      end

      it "says business moved on when the business of the day was called on" do
        rendered = compile_summary(closure_data, template_id: 22, motion_text: "That the business of the day be called on.")

        expect(rendered).to include("There was no question before the Chair to decide")
        expect(rendered).not_to include("then voted on the question itself")
      end
    end

    # The closing sentence of a reading used to be chosen by the bill stage alone, so a defeated
    # division said "the bill has now passed" directly after "which means it was unsuccessful".
    # Both halves of the answer are needed: the template says which reading the chamber was
    # asked about, the result says whether it agreed (KNOWN_ISSUES.md, KI-1).
    describe "Templates 29 and 6, reporting the result of the reading and not just the reading" do
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

      def compile_reading(data, reading)
        compile_summary(data, template_id: { "second" => 29, "third" => 6 }.fetch(reading),
                              motion_text: "That this bill be now read a #{reading} time.")
      end

      it "names the reading each template is about in its vote sentence" do
        expect(compile_reading(bill_division_data(result: "passed"), "second")).to include("through its second reading")
        expect(compile_reading(bill_division_data(result: "passed"), "third")).to include("through its third reading")
      end

      it "does not say a bill passed when the third reading was defeated" do
        rendered = compile_reading(bill_division_data(result: "negatived"), "third")

        expect(rendered).to include("which means it was unsuccessful.")
        expect(rendered).to include("which means it was unsuccessful. The bill did not pass the Senate.")
        expect(rendered).not_to include("has now passed")
      end

      # The chair puts this when a guillotine's time runs out, with nobody moving it
      # (ProceduralRouter#third_reading), so there is no mover to name either.
      it "names every remaining stage, and no mover, when the question takes the remaining stages together" do
        question = "The question now is that the remaining stages of the bill be agreed to, and the bill be now passed."
        data = bill_division_data(result: "passed").except(:mover_name)
        rendered = compile_summary(data, template_id: 6, question_text: question)

        expect(rendered).to include("a motion to pass the [Example Bill 2026](https://example.com/bills/example-bill-2026) " \
                                    "through all its remaining stages, which means it was successful.")
        expect(rendered).not_to include("introduced by")
      end

      # The guillotine is why nobody moved it and nobody debated it, which a reader cannot see
      # from the question alone.
      it "says the question was put under a limitation of debate, in the chair's own words" do
        question = "The question now is that the remaining stages of the bill be agreed to, and the bill be now passed."
        expiry = "Pursuant to order agreed on 18 August 2026, the time allotted for consideration of 12 bills has expired."
        rendered = compile_summary(bill_division_data(result: "passed").except(:mover_name), template_id: 6,
                                                                                             question_text: question, limitation: expiry)

        expect(rendered).to include("which means it was successful. The bill has now passed the Senate.\n\n" \
                                    "This question was put under a limitation of debate, often called a 'guillotine'.\n\n" \
                                    "At 1:15 PM, Senator Robin Castellan, in the chair, said:\n\n> #{expiry}\n\n" \
                                    "Once the time allotted for debate has expired, the chair puts the questions still to " \
                                    "be decided one after another, without further debate.\n\n")
      end

      it "says nothing about a limitation of debate, and leaves no gap, when there was none" do
        question = "The question now is that the remaining stages of the bill be agreed to, and the bill be now passed."
        rendered = compile_summary(bill_division_data(result: "passed"), template_id: 6, question_text: question)

        expect(rendered).not_to include("limitation of debate")
        expect(rendered).not_to match(/\n{3,}/)
      end

      it "does not say the chamber agreed with the bill when the second reading was defeated" do
        rendered = compile_reading(bill_division_data(result: "negatived"), "second")

        expect(rendered).to include("which means it was unsuccessful.")
        expect(rendered).to include("did not agree to the bill in principle, so it goes no further at this stage")
        expect(rendered).not_to include("agreed with the main idea")
      end

      it "still reports an agreed second reading as agreeing to the bill in principle" do
        rendered = compile_reading(bill_division_data(result: "passed"), "second")

        expect(rendered).to include("which means it was successful.")
        expect(rendered).to include("agreed with the main idea of the bill and can now consider it in greater detail")
      end

      # Where a bill goes next depends on where it started, which TVFY does not record. A bill
      # that came from the other chamber and passes here unamended goes to the Governor-General
      # for assent, not back across (House Guide to Procedures, pp. 87-88), so an unprompted
      # "will go to the House of Representatives" was wrong for that whole class of division.
      it "says only that the bill passed when the originating chamber is unknown" do
        rendered = compile_reading(bill_division_data(result: "passed"), "third")

        expect(rendered).to include("which means it was successful. The bill has now passed the Senate.")
        expect(rendered).not_to include("House of Representatives")
      end

      it "names the destination chamber when the bill is known to have started in this one" do
        data = bill_division_data(result: "passed", extra: { bill_originating_house: "senate" })

        rendered = compile_reading(data, "third")

        expect(rendered).to include("It started in the Senate, so it now goes to the House of Representatives.")
      end

      it "stays silent on the destination when the bill started in the other chamber" do
        data = bill_division_data(result: "passed", extra: { bill_originating_house: "representatives" })

        rendered = compile_reading(data, "third")

        expect(rendered).to include("which means it was successful. The bill has now passed the Senate.")
        expect(rendered).not_to include("it now goes to")
      end

      # Section 128's explanation is about the third reading specifically, and it already
      # distinguished a carried bill from a defeated one, so it must survive the change above.
      it "keeps the Section 128 explanation for a defeated Constitution Alteration third reading" do
        data = bill_division_data(result: "negatived",
                                  extra: { bill_name: "Constitution Alteration (Fictional Reform) 2026" })

        rendered = compile_reading(data, "third")

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

      def compile_stand_as_printed(data, template_id: 28)
        compile_summary(data, template_id: template_id, motion_text: "That clause 4 stand as printed.")
      end

      # The Senate puts an amendment to omit part of a bill as "That the [unit] stand as
      # printed", so defeating the question is what omits the unit. The reported vote
      # direction has to stay true to the question, because that is what the aye and no
      # counts beside the summary are counts of, and the consequence is stated separately.
      it "reports a defeated question as a vote against it, and says the part was omitted" do
        rendered = compile_stand_as_printed(division_data.merge(result: "negatived"))

        expect(rendered).to include("voted against a question that part of the Migration Amendment Bill 2026 stand as printed")
        expect(rendered).to include("defeating the question is what omitted that part of the bill")
        expect(rendered).to include("the text of the bill has changed accordingly")
      end

      it "reports a carried question as a vote for it, and says the part was kept" do
        rendered = compile_stand_as_printed(division_data.merge(result: "passed"))

        expect(rendered).to include("voted for a question that part of the Migration Amendment Bill 2026 stand as printed")
        expect(rendered).to include("kept that part of the bill unchanged and defeated the amendment to omit it")
      end

      it "leaves the effect clause out of every other template" do
        rendered = compile_stand_as_printed(division_data.merge(result: "negatived"), template_id: 3)

        expect(rendered).not_to include("stand as printed, defeating the question")
      end

      # KI-45: a draft never said which parts the vote kept, or whose
      # amendments it defeated.
      it "names the parts the question named, and who circulated the amendments to omit them, in Hansard's words" do
        question = "I will now deal with the remaining amendments circulated by the Example Party. The first question is " \
                   "that part 3 of schedule 1; items 7 and 9 in schedule 1; and section 12A in item 4 in schedule 2 stand as printed."
        circulated = DivisionSummaryPipeline::Circulation.new(by: "the Example Party", member: nil, plural: true)
        rendered = compile_summary(division_data.merge(result: "passed"), template_id: 28, question_text: question,
                                                                          motion_text: "(2) Schedule 1, Part 3, to be opposed.",
                                                                          circulation: circulated)

        expect(rendered).to include("which means the question was successful. The question named \"part 3 of schedule 1; " \
                                    "items 7 and 9 in schedule 1; and section 12A in item 4 in schedule 2\". The amendments " \
                                    "to omit them were circulated by the Example Party. Because the question was")
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

      def compile_quorum(data)
        compile_summary(data, template_id: 15, motion_text: "That the House take the next item of business.")
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

        rendered = compile_summary(division_data, template_id: 6, motion_text: "That this bill be now read a third time.")

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

        rendered = compile_summary(division_data, template_id: 6, motion_text: "That this bill be now read a third time.")

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

        rendered = compile_summary(division_data, template_id: 15, motion_text: "That the Senate records its concern.")

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

        rendered = compile_summary(division_data, template_id: 15, motion_text: "That the House records its concern.")

        expect(rendered).to include("an equally divided House of Representatives")
        expect(rendered).to include("decided by the casting vote of the occupant of the Chair")
        expect(rendered).to include("Section 40 of the Constitution")
      end

      # House S.O. 58: a division showing fewer than a quorum voting makes no decision. The
      # quorum is one fifth of the House, so it moved from 30 to 31 when the House grew to 151.
      it "flags a want of quorum against the 30-member threshold for a pre-2019 division" do
        rendered = compile_quorum(quorum_division_data(date: "2015-03-04"))

        expect(rendered).to include("which means it was not decided, because fewer than a quorum of members voted.")
        expect(rendered).to include("only 24 members voted, fewer than the quorum of 30")
        expect(rendered).to include("Under House Standing Order 58")
      end

      it "flags a want of quorum against the 31-member threshold once the House grew to 151" do
        rendered = compile_quorum(quorum_division_data(date: "2021-03-04"))

        expect(rendered).to include("fewer than the quorum of 31")
      end

      it "says nothing about a quorum when the date is unknown" do
        rendered = compile_quorum(quorum_division_data(date: nil))

        expect(rendered).not_to include("quorum")
      end

      # The Guides to Senate Procedure set out no rule voiding a Senate division for want of a
      # quorum, so the pipeline does not invent one, and senators may simply abstain by
      # staying away.
      it "never raises a quorum notice for a Senate division" do
        data = quorum_division_data(date: "2021-03-04").merge(house: "senate")

        expect(compile_quorum(data)).not_to include("quorum")
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

        rendered = compile_summary(division_data, template_id: 15, motion_text: "That this bill be agreed to.")
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
          mover_name: "Casey Marlowe",
          mover_party: "Labor",
          house: "representatives",
          date: "2026-08-19"
        }

        rendered = compile_summary(
          division_data,
          template_id: 24,
          motion_text: "That the member for Brightwater be suspended from the service of the House.",
          facts: { target_electorate: "Brightwater" }
        )
        expect(rendered).to start_with("**Jargon Explainer:** *This disciplinary vote suspends a member")
        expect(rendered).to include("that Brightwater MP [Alex Downey](/people/representatives/brightwater/alex_downey) (Liberal) be suspended from the service of the House of Representatives")
      end

      it "compiles Template 25 (Dissent from Ruling)" do
        division_data = {
          time: "11:45 AM",
          amount: "majority",
          result: "negatived",
          mover_name: "Drew Pemberton",
          mover_party: "Liberal",
          house: "representatives"
        }

        rendered = compile_summary(
          division_data,
          template_id: 25,
          motion_text: "That the Speaker's ruling be dissented from.",
          explanations: ["The Minister's answer was not directly relevant."]
        )
        expect(rendered).to start_with("**Jargon Explainer:** *A motion of dissent challenges a formal procedural ruling")
        expect(rendered).to include("to dissent from a ruling of the Chair, which means it was unsuccessful.")
        expect(rendered).to include("Drew Pemberton MP said:\n\n> The Minister's answer was not directly relevant.")
      end

      it "compiles Template 26 (Adjournment)" do
        division_data = {
          time: "10:30 PM",
          amount: "majority",
          result: "passed",
          mover_name: "Casey Marlowe",
          mover_party: "Labor",
          house: "representatives"
        }

        rendered = compile_summary(division_data, template_id: 26, motion_text: "That the House do now adjourn.")
        expect(rendered).to start_with("**Jargon Explainer:** *At a set time each sitting day the chair proposes that the chamber do now adjourn.")
        expect(rendered).to include("that the House of Representatives do now adjourn, which means it was successful.")
      end

      it "compiles Template 27 (Taking Note)" do
        division_data = {
          time: "04:15 PM",
          amount: "majority",
          result: "passed",
          mover_name: "Tamsin Hale",
          mover_party: "Labor",
          house: "senate"
        }

        rendered = compile_summary(
          division_data,
          template_id: 27,
          motion_text: "That the Senate take note of the document.",
          explanations: ["Taking note of the statement will enable a debate on foreign affairs."]
        )
        expect(rendered).to start_with("**Jargon Explainer:** *A motion to \"take note\" is the device")
        expect(rendered).to include("to take note of the matter set out in the motion text below, which means it was successful.")
        expect(rendered).to include("Senator Tamsin Hale said:\n\n> Taking note of the statement will enable a debate on foreign affairs.")
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

      def compile_message(data, motion_text)
        compile_summary(data, template_id: 7, motion_text: motion_text)
      end

      it "says a defeated 'does not insist' is what insists on the amendments" do
        rendered = compile_message(
          message_division(result: "negatived"),
          "That the committee does not insist on its amendments to which the House of Representatives has disagreed."
        )

        expect(rendered).to include("that the Senate not insist on its own amendments")
        expect(rendered).to include("defeating it is what insists on the amendments")
        expect(rendered).not_to include("to agree to the amendments the House of Representatives made")
      end

      it "attributes the amendments to this chamber, not the other one, on an insist question" do
        rendered = compile_message(message_division(result: "passed"), "That the committee insists on its amendments.")

        expect(rendered).to include("that the Senate insist on its own amendments")
        expect(rendered).to include("the Senate kept its own amendments")
      end

      it "flips an equally divided 'does not insist' the other way, as the Senate guide does" do
        data = message_division(result: "negatived").merge(aye_votes: 36, no_votes: 36, tied: true)
        rendered = compile_message(data, "That the committee does not insist on its amendments.")

        expect(rendered).to include("the amendments are not insisted on")
        expect(rendered).to include("chair of committees makes a statement")
      end

      it "still describes a plain agree question as agreeing to the other chamber's amendments" do
        rendered = compile_message(message_division(result: "passed", house: "representatives"),
                                   "That the amendments made by the Senate be agreed to.")

        expect(rendered).to include("to agree to the amendments the Senate made")
        expect(rendered).to include("accepted the Senate's changes to the bill")
      end

      it "says a carried disagree rejects them and returns the bill with reasons" do
        rendered = compile_message(message_division(result: "passed", house: "representatives"),
                                   "That the amendments be disagreed to.")

        expect(rendered).to include("to disagree to the amendments the Senate made")
        expect(rendered).to include("rejected the Senate's changes")
      end

      it "explains section 53 when the question is about requests rather than amendments" do
        rendered = compile_message(message_division(result: "passed"),
                                   "That the requests be made to the House of Representatives.")

        expect(rendered).to include("Section 53 of the Constitution")
        expect(rendered).to include("requests for amendments")
      end

      # The message form is read from the motion where one was recorded, and from the chair's
      # question where it was not.
      it "reads the form from the question put when no motion was recorded" do
        rendered = compile_summary(
          message_division(result: "negatived"),
          template_id: 7,
          question_text: "The question is that the committee does not insist on its amendments."
        )

        expect(rendered).to include("that the Senate not insist on its own amendments")
        expect(rendered).to include("defeating it is what insists on the amendments")
      end
    end

    # House Guide pp. 40-41: calling on the business of the day exists only to curtail a
    # discussion on a matter of public importance, and is provided "because there is no
    # question before the Chair during an MPI". Describing it as a closure that forces an
    # immediate vote contradicted the trailing clause in the same paragraph (KI-3).
    # KI-46: "to end the debate on bill" in every closure not on a bill.
    describe "Template 22, a closure on a bill and on anything else" do
      let(:closure) { { time: "12:31 PM", result: "passed", house: "senate" } }

      it "says the debate ended, and names no bill, when the division has none" do
        rendered = compile_summary(closure, template_id: 22, motion_text: "That the question be put.")

        expect(rendered).to include("a procedural motion to end the debate and put the question immediately")
        expect(rendered).not_to include("on bill")
      end

      # KI-54.
      it "says what the debate it ended was on, when Stage 1 found it" do
        interpretation, evidence = summary_inputs(template_id: 22, motion_text: "That the question be put.")
        suspension = described_class.compile(closure, interpretation, evidence.with(closed_template_id: 17))
        second_reading = described_class.compile(closure.merge(bill_name: "Example Bill 2026", bill_link: "https://example.com/bill"),
                                                 interpretation, evidence.with(closed_template_id: 29))

        expect(suspension).to include("to end the debate on a motion to suspend standing orders and put the question immediately")
        expect(second_reading).to include("to end the debate on the second reading of the [Example Bill 2026](https://example.com/bill)")
      end

      it "names the bill after \"the\" when there is one" do
        rendered = compile_summary(closure.merge(bill_name: "Example Bill 2026", bill_link: "https://example.com/bill"),
                                   template_id: 22, motion_text: "That the question be put.")

        expect(rendered).to include("to end the debate on the [Example Bill 2026](https://example.com/bill) and put the question")
      end
    end

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
        rendered = compile_summary(
          closure_division(result: "passed"),
          template_id: 22,
          motion_text: "That the business of the day be called on."
        )

        expect(rendered).to include("ends a discussion on a matter of public importance")
        expect(rendered).to include("to call on the business of the day and end the discussion")
        expect(rendered).to include("There was no question before the Chair to decide")
        expect(rendered).not_to include("put the question immediately")
        expect(rendered).not_to include("which is put to a separate vote straight afterwards")
      end

      it "describes the ballot closure used in the election of a Speaker" do
        rendered = compile_summary(
          closure_division(result: "passed"),
          template_id: 22,
          motion_text: "That the ballot be taken now."
        )

        expect(rendered).to include("to end the debate and take the ballot immediately")
        expect(rendered).to include("then proceeded to the ballot")
      end

      it "says the debate continued when an ordinary closure was defeated" do
        rendered = compile_summary(
          closure_division(result: "negatived"),
          template_id: 22,
          motion_text: "That the question be now put."
        )

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
        rendered = compile_summary(
          general_division,
          template_id: 15,
          motion_text: "That the House approves the form of agreement set out in the schedule."
        )

        expect(rendered).not_to include("has no legal effect")
      end

      it "still says so when the motion records an opinion" do
        rendered = compile_summary(
          general_division,
          template_id: 15,
          motion_text: "That the House notes the state of housing supply."
        )

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

      def compile_suspension(data, motion_text)
        compile_summary(data, template_id: 17, motion_text: motion_text)
      end

      it "takes the purpose from the motion's own words" do
        rendered = compile_suspension(suspension_division,
                                      "That so much of the standing orders be suspended as would prevent the member for " \
                                      "Fairview moving a motion relating to aged care funding forthwith.")

        expect(rendered).to include("a motion introduced by Representative [Fictional Member](https://example.com/m) (Labor) " \
                                    "to suspend standing orders \"as would prevent the member for Fairview moving a motion " \
                                    "relating to aged care funding forthwith\". The vote was successful.")
        expect(rendered).not_to include("urgent matter regarding an urgent matter")
        expect(rendered).not_to include("to allow the House of Representatives to debate an urgent matter")
      end

      # There is no model-written topic to fall back on any more, so a motion that does not
      # state its purpose in the usual form gets no purpose clause at all.
      it "prints no purpose clause when the motion does not use the usual form" do
        rendered = compile_suspension(suspension_division, "That standing order 65 be suspended for this sitting.")

        expect(rendered).to include("(Labor) to suspend standing orders. The vote was successful.")
        expect(rendered).not_to include("standing orders \"as would prevent")
      end

      # KI-26: unquoted, a motion moved in the first person read as They Vote
      # For You speaking.
      it "quotes a purpose the mover states in the first person, so it is never the site's own words" do
        rendered = compile_suspension(suspension_division,
                                      "That so much of the standing orders be suspended as would prevent me from moving a " \
                                      "motion relating to the conduct of the business of the Senate.")

        expect(rendered).to include("to suspend standing orders \"as would prevent me from moving a motion relating to the " \
                                    "conduct of the business of the Senate\".")
        expect(rendered).not_to include("the rules that would otherwise prevent me")
      end

      # KI-5: a suspension moved without notice needs an absolute majority, and the question
      # alone does not say how it was moved.
      it "flags a suspension carried on fewer votes than an absolute majority" do
        data = suspension_division.merge(aye_votes: 70, no_votes: 68, date: "2024-06-05")

        rendered = compile_suspension(data, "That so much of the standing orders be suspended as would prevent a motion being moved.")

        expect(rendered).to include("Notice: a motion to suspend standing orders moved without notice needs an absolute majority")
        expect(rendered).to include("at least 76")
        expect(rendered).to include("the question alone does not record which it was")
      end

      # House S.O. 47(c)(ii) as at 23 July 2025, and "by leave" only of the House (House Guide pp. 2-3).
      it "gives each chamber's own ways to carry a suspension on a simple majority" do
        house = compile_suspension(suspension_division.merge(aye_votes: 70, no_votes: 68, date: "2024-06-05"),
                                   "That so much of the standing orders be suspended as would prevent a motion being moved.")
        senate = compile_suspension(suspension_division.merge(house: "senate", aye_votes: 30, no_votes: 28, date: "2024-06-05"),
                                    "That so much of the standing orders be suspended as would prevent a motion being moved.")

        expect(house).to include("by leave, or with the agreement of the Leader of the House and the Manager of Opposition Business")
        expect(senate).to include("Moved on notice or under a contingent notice, a majority of those voting is enough.")
      end

      it "says nothing about an absolute majority when the ayes clear it anyway" do
        data = suspension_division.merge(aye_votes: 84, no_votes: 54, date: "2024-06-05")

        rendered = compile_suspension(data, "That so much of the standing orders be suspended as would prevent a motion being moved.")

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
        rendered = compile_summary(
          suspension_of_member("representatives"),
          template_id: 24,
          motion_text: "That the member be suspended from the service of the House.",
          facts: { target_name: "Fictional Member" }
        )

        expect(rendered).to include("24 hours from the time of suspension on a first occasion")
        expect(rendered).to include("seven consecutive sittings after that day on a third or later occasion")
        expect(rendered).to include("be suspended from the service of the House of Representatives")
        expect(rendered).not_to include("excluded for the remainder of the sitting")
      end

      # House S.O. 94(d) as at 23 July 2025: only the second and third occasions leave out the day.
      it "does not say the first occasion leaves out the day of the suspension" do
        rendered = compile_summary(suspension_of_member("representatives"), template_id: 24,
                                                                            motion_text: "That the member be suspended.",
                                                                            facts: { target_name: "Fictional Member" })

        expect(rendered).to include("for the three consecutive sittings after the day of the suspension on a second occasion")
        expect(rendered).not_to include("in each case not counting the day")
      end

      it "uses the Senate's form of words and does not assert its suspension periods" do
        rendered = compile_summary(
          suspension_of_member("senate"),
          template_id: 24,
          motion_text: "That the senator be suspended from the sitting of the Senate.",
          facts: { target_name: "Fictional Senator" }
        )

        expect(rendered).to include("be suspended from the sitting of the Senate")
        expect(rendered).to include("standing order 204")
        expect(rendered).not_to include("24 hours from the time of suspension")
      end
    end

    # House S.O.s 31 and 32(a): at the scheduled time the Speaker proposes the adjournment
    # with nobody moving it, so there is no mover to name (KI-12).
    describe "Template 26, an adjournment with no mover" do
      it "leaves the mover out rather than naming 'a member'" do
        rendered = compile_summary(
          { time: "08:00 PM", amount: "majority", result: "negatived", house: "representatives" },
          template_id: 26,
          motion_text: "That the House do now adjourn."
        )

        expect(rendered).to include("voted against a procedural motion that the House of Representatives do now adjourn")
        expect(rendered).not_to include("introduced by")
        expect(rendered).to include("returned to the business it was part way through")
      end
    end

    # The cosmetic tidying passes used to run over the whole compiled document, including the
    # blockquoted motion text, so they silently edited quoted Hansard.
    describe "verbatim quoted text" do
      let(:division_data) do
        { time: "03:40 PM", amount: "majority", result: "passed", house: "representatives", mover_name: "Fictional Member" }
      end

      it "leaves runs of spaces inside the quoted motion alone" do
        rendered = compile_summary(
          division_data,
          template_id: 15,
          motion_text: "That the House notes:    (a) the first thing; and    (b) the second thing."
        )

        expect(rendered).to include("> That the House notes:    (a) the first thing; and    (b) the second thing.")
      end

      it "does not collapse a doubled 'the' that a member actually said" do
        rendered = compile_summary(
          division_data,
          template_id: 15,
          motion_text: "That the House notes the the minister misspoke."
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

        rendered = compile_summary(division_data, template_id: 15, motion_text: "That the House records its concern.")

        expect(rendered).to include("an equally divided House of Representatives voted on a")
        expect(rendered).to include("not decided by the division figures, which were equal")
        expect(rendered).to include("do not record which way that casting vote went")
      end
    end

    # What the September 2026 test runs got wrong in drafts that otherwise passed.
    describe "facts the drafts from real divisions got wrong" do
      let(:senate_data) { { time: "11:00 AM", amount: "majority", result: "passed", house: "senate" } }

      def compile_real(division_data, template_id, motion_text: "That the motion be agreed to.", **inputs)
        compile_summary(division_data, template_id: template_id, motion_text: motion_text, **inputs)
      end

      # Whip#free? is true for any whipless party (independents, the presiding officer), which
      # is nearly every division; Whip#free_vote? is the list of actual conscience votes.
      it "does not call a division a conscience vote because an independent has no whip" do
        division = create(:division, house: "senate", date: Date.new(2026, 9, 14), number: 7)
        create(:whip, division: division, party: "Independent", whip_guess: "none")

        expect(compile_real(division, 15)).not_to include("conscience vote")
      end

      it "still calls a listed conscience vote one, in the Senate's own words" do
        division = create(:division, house: "senate", date: Date.new(2022, 11, 24), number: 1)
        create(:whip, division: division, party: "Australian Labor Party", whip_guess: "none")

        expect(compile_real(division, 15)).to include("Senators were not bound by party whips")
      end

      it "names the mover Stage 1 found when the division data has none" do
        mover = DivisionSummaryPipeline::MemberResolver.named("Jo Rae")

        rendered = compile_real(senate_data.merge(house: "representatives"), 15, mover: mover)

        expect(rendered).to include("introduced by Jo Rae MP")
      end

      it "prefers a mover the division data supplies" do
        mover = DivisionSummaryPipeline::MemberResolver.named("Jo Rae")

        rendered = compile_real(senate_data.merge(mover_name: "Sam Taylor"), 15, mover: mover)

        expect(rendered).to include("introduced by Senator Sam Taylor")
      end

      # T3 once printed the model's unresolved speaker after a hard-coded "Senator". The model
      # can no longer name anyone, but an explanation passage still carries the speaker name
      # Hansard printed, which for a presiding officer is the office rather than a person, and is
      # printed as the office ("the President") with no chamber title in front of it.
      it "does not print an unresolved speaker as the mover" do
        interpretation, evidence = summary_inputs(template_id: 3, motion_text: "That the motion be agreed to.")
        passage = summary_excerpt("The amendment fixes the rail safety rules.", speaker: "The PRESIDENT", found_by: :model)
        evidence = evidence.with(explanations: [passage])

        rendered = described_class.compile(senate_data, interpretation, evidence)

        expect(rendered).to include("voted for an amendment to the bill")
        expect(rendered).not_to include("PRESIDENT")
        expect(rendered).not_to include("a member")
      end

      # There is no model-written topic any more; the check now is that nothing but a bill
      # record, not even the debate heading, is printed as the bill's title.
      it "does not print anything but a bill record as though it were the bill's title" do
        rendered = compile_real(
          senate_data.merge(result: "negatived", name: "Early childhood wages"),
          2,
          declines_second_reading: false
        )

        expect(rendered).to include("a second reading amendment to the bill,")
        expect(rendered).not_to include("Early childhood wages,")
      end

      it "quotes the matter of urgency itself rather than calling the topic urgent" do
        motion = "That, in the opinion of the Senate, the following is a matter of urgency:\n\n" \
                 "The need for the Government to publish its housing plan."

        rendered = compile_real(senate_data, 16, motion_text: motion)

        expect(rendered).to include("declaring a matter of urgency: \"The need for the Government to publish its housing plan\"")
        expect(rendered).not_to include("declaring Housing plan urgency")
      end

      it "declares a matter of urgency without naming one when the motion does not state it" do
        rendered = compile_real(senate_data, 16, motion_text: "That the matter be considered urgent.")

        expect(rendered).to include("declaring a matter of urgency, which means it was successful.")
      end

      it "keeps a long suspension purpose whole, including a bill title with \"No. 3\" in it" do
        purpose = "the member for Exampleton moving a motion to bring on the Example Measures Amendment Bill 2026 " \
                  "(No. 3), having earlier been referred to the Federation Chamber, for further consideration in " \
                  "detail by the House immediately and for the remaining stages to be passed without delay"
        motion = "That so much of the standing orders be suspended as would prevent #{purpose}."

        rendered = compile_real(senate_data.merge(house: "representatives"), 17, motion_text: motion)

        expect(rendered).to include("\"as would prevent #{purpose}\"")
        expect(rendered).not_to include("regarding Example topic")
      end

      # KI-26: spliced in after "specifically that", the model's phrase
      # printed "specifically that That".
      describe "Template 19, what the rearrangement does" do
        let(:long_motion) { "That—\n\n(1) On Tuesday the hours of meeting be midday till adjournment.\n\n(2) Divisions may take place after 6.30 pm." }

        it "quotes a one-paragraph motion's own words, found by rule" do
          rendered = compile_real(senate_data, 19, motion_text: "That the debate be adjourned.")

          expect(rendered).to include("to rearrange the business of the Senate (\"That the debate be adjourned.\"), which means")
        end

        it "quotes the phrase the model pointed at when the motion is long" do
          rendered = compile_real(senate_data, 19, motion_text: long_motion,
                                                   facts: { rearrangement_description: "the hours of meeting be midday till adjournment" })

          expect(rendered).to include("the business of the Senate (\"the hours of meeting be midday till adjournment\"), which means")
        end

        it "ends the sentence at the business when there is neither" do
          rendered = compile_real(senate_data, 19, motion_text: long_motion)

          expect(rendered).to include("to rearrange the business of the Senate, which means it was successful.")
          expect(rendered).not_to include("specifically")
        end
      end

      it "names the bill a guillotine limits debate on when the division has one" do
        rendered = compile_real(senate_data.merge(bill_name: "Example Bill 2026", bill_link: "https://example.com/bill"), 18)

        expect(rendered).to include("to limit debate and force a vote on the [Example Bill 2026](https://example.com/bill), which means")
      end
    end
  end

  # Every quoted part of a summary is Hansard's own text from Evidence, printed whole under a
  # line saying who said it and when (EvidenceSections).
  # KNOWN_ISSUES.md KI-29: the Template 2 explainer described only the House.
  # KI-43: under a limitation of debate the chair puts circulated amendments
  # with nobody moving them, and a draft credited a party's amendments to a minister who had not.
  describe "amendments the chair put without anyone moving them" do
    let(:greens) { DivisionSummaryPipeline::Circulation.new(by: "the Example Party", member: nil, plural: true) }
    let(:terms) { "Omit all words after \"That\", substitute \"the Senate rejects the bill\"." }

    it "says who circulated them, never who moved them, and counts them right" do
      rendered = compile_summary({ time: "12:27 PM", result: "negatived", house: "senate", bill_name: "Example Bill 2026" },
                                 template_id: 2, declines_second_reading: true, motion_text: terms, circulation: greens)

      expect(rendered).to include("voted against second reading amendments circulated by the Example Party to the " \
                                  "Example Bill 2026, which means they were unsuccessful.")
      expect(rendered).to include("Because the amendments sought to refuse the bill a second reading, a vote for them")
      expect(rendered).to include("The following amendments, circulated by the Example Party, were put:\n\n> Omit all words")
      expect(rendered).not_to include("moved", "introduced by")
    end

    it "reads the same way in the House, for one amendment and a member the chair names by seat" do
      member = DivisionSummaryPipeline::Circulation.new(by: "the member for Exampleton", member: nil, plural: false)
      rendered = compile_summary({ time: "12:27 PM", result: "negatived", house: "representatives" },
                                 template_id: 4, motion_text: "(1) Clause 2, page 2 (line 4), omit the clause.",
                                 circulation: member)

      expect(rendered).to include("voted against an amendment circulated by the member for Exampleton to the bill during " \
                                  "the Consideration in Detail stage, which means it was unsuccessful.")
      expect(rendered).to include("The following amendment, circulated by the member for Exampleton, was put:")
    end

    it "says nothing about who when Hansard does not" do
      unknown = DivisionSummaryPipeline::Circulation.new(by: nil, member: nil, plural: true)
      rendered = compile_summary({ time: "12:27 PM", result: "passed", house: "senate" },
                                 template_id: 3, motion_text: "(1) Clause 2, omit the clause.", circulation: unknown)

      expect(rendered).to include("voted for amendments to the bill, which means they were successful.",
                                  "The following amendments were put:")
    end
  end

  # KI-24: "Representative Example" is not Australian usage; the site's own
  # form is "Example MP" (Member#full_name_no_electorate).
  # KI-52: the House programming a bill by suspending standing orders is not
  # a guillotine (House Guide p. 75), and the draft said nothing at all.
  describe "a question the House put immediately under a resolution agreed earlier" do
    it "says so in words of its own, with the date from the Speaker's words, and does not call it a guillotine" do
      rendered = compile_summary({ time: "12:39 PM", result: "negatived", house: "representatives" },
                                 template_id: 2, declines_second_reading: false, motion_text: "That all words after \"That\" be omitted.",
                                 limitation: "In accordance with the resolution agreed to on 12 August 2026, I will put the question immediately.")

      expect(rendered).to include("This question was put without further debate, under an arrangement the House of " \
                                  "Representatives agreed on 12 August 2026.\n\nAt 1:15 PM, Robin Castellan MP, in the chair, " \
                                  "said:\n\n> In accordance with the resolution agreed to on 12 August 2026, I will put the question immediately.")
      expect(rendered).not_to include("guillotine")
    end
  end

  # KI-53: the whole motion is printed below, so a reader took every part of
  # it to have been voted on.
  describe "a divided question" do
    it "says the vote was on the motion without the parts put separately, in the chair's words" do
      rendered = compile_summary({ time: "12:13 PM", result: "passed", house: "senate" }, template_id: 18,
                                                                                          motion_text: "That—\n\n(1) On Tuesday the hours of meeting be midday till adjournment.",
                                                                                          question_text: "I'm going to put the rest of the motion, and then I'm going to put 2(a) and (b). " \
                                                                                                         "The question is that the substantive motion, minus 2(a) and (b), be agreed to.")

      expect(rendered).to include("The question was divided, so this vote was on the motion without \"2(a) and (b)\"; " \
                                  "those parts were put to the Senate as a separate question.")
    end

    it "says nothing for a question put whole" do
      rendered = compile_summary({ time: "12:13 PM", result: "passed", house: "senate" }, template_id: 18,
                                                                                          motion_text: "That the bill be considered urgent.",
                                                                                          question_text: "The question is that the motion be agreed to.")

      expect(rendered).not_to include("The question was divided")
    end
  end

  # KI-55.
  describe "what a draft says about who moved what" do
    let(:senate_data) { { time: "4:30 PM", result: "negatived", house: "senate" } }

    it "names who proposed a matter of urgency someone else moved" do
      interpretation, evidence = summary_inputs(template_id: 16, motion_text: "That the following is a matter of urgency: fairness.",
                                                mover: DivisionSummaryPipeline::MemberResolver.named("Sam Okafor"))
      rendered = described_class.compile(senate_data, interpretation,
                                         evidence.with(proposer: DivisionSummaryPipeline::MemberResolver.named("Morgan Treloar")))

      expect(rendered).to include("a motion introduced by Senator Sam Okafor on behalf of Senator Morgan Treloar declaring a " \
                                  "matter of urgency")
    end

    it "does not say words incorporated in Hansard were said" do
      interpretation, evidence = summary_inputs(template_id: 29, motion_text: "That this bill be now read a second time.",
                                                mover: DivisionSummaryPipeline::MemberResolver.named("Jo Marlowe"))
      incorporated = DivisionSummaryPipeline::Evidence::Excerpt.new(text: "This bill makes the levy fairer.", unit_ids: ["S1.9"],
                                                                    speaker: "Jo Marlowe", speaker_gid: nil, time: "19:14",
                                                                    date: nil, found_by: :model, incorporated: true)
      rendered = described_class.compile(senate_data, interpretation, evidence.with(explanations: [incorporated]))

      expect(rendered).to include("At 7:14 PM, Senator Jo Marlowe's speech, incorporated in Hansard, reads:\n\n> This bill makes the levy fairer.")
      expect(rendered).not_to include("Jo Marlowe said:")
    end

    it "leaves out Motion Introduction and Motion Text when the chair put the question with nobody moving it" do
      interpretation, evidence = summary_inputs(template_id: 6, question_text: "The question now is that the remaining stages of " \
                                                                               "the bill be agreed to and the bill be now passed.")
      rendered = described_class.compile(senate_data.merge(result: "passed"), interpretation, evidence.with(put_without_mover: true))

      expect(rendered).not_to include("### Motion Introduction", "### Motion Text", "No separate motion was recorded",
                                      "No explanatory claims recorded.")
      expect(rendered).to include("### Question Put")
    end

    # KI-56: once a Bills Digest is supplied, the Parliamentary Library's key
    # points and the mover's own case would have sat in one section with nothing to tell them apart.
    it "gives the mover's words their own heading, apart from the Bills Digest" do
      [1, 5, 6, 29].each do |template_id|
        rendered = compile_summary(senate_data.merge(result: "passed"), template_id: template_id, motion_text: "That it pass.",
                                                                        explanations: ["The bill is fair."])

        expect(rendered).to match(/> No Bill Digest found\.\n\n### About the Motion\n\nAt 1:27 PM, .* said:/), "Template #{template_id}"
      end
    end
  end

  describe "naming members of the House" do
    let(:house_data) { { time: "12:39 PM", result: "negatived", house: "representatives" } }

    it "names the mover, the speaker quoted and the member in the chair as \"Example MP\"" do
      rendered = compile_summary(house_data, template_id: 2, declines_second_reading: false,
                                             motion_text: "That all words after \"That\" be omitted.",
                                             explanations: ["The measure needs review."],
                                             question_text: "The question is that the amendment be agreed to.",
                                             mover: DivisionSummaryPipeline::MemberResolver.named("Jo Rae"))

      expect(rendered).to include("a second reading amendment introduced by Jo Rae MP to the bill")
      expect(rendered).to include("At 1:27 PM, Jo Rae MP said:")
      expect(rendered).to include("At 1:30 PM, Robin Castellan MP, in the chair, put the following question:")
      expect(rendered).not_to include("Representative ", "the Speaker")
    end

    it "keeps \"Senator\" in front of a senator's name" do
      rendered = compile_summary(house_data.merge(house: "senate"), template_id: 15, motion_text: "That the Senate notes it.",
                                                                    mover: DivisionSummaryPipeline::MemberResolver.named("Jo Rae"))

      expect(rendered).to include("introduced by Senator Jo Rae")
    end
  end

  # KI-48.
  describe "wording that read as machine output" do
    let(:senate_data) { { time: "12:35 PM", result: "passed", house: "senate", bill_name: "Example Bill 2026" } }

    it "counts rebels in words, not \"senator(s)\"" do
      one = compile_summary(senate_data.merge(rebellions: 1), template_id: 15, motion_text: "That the Senate notes it.")
      two = compile_summary(senate_data.merge(rebellions: 2, house: "representatives"), template_id: 15, motion_text: "That it be noted.")

      expect(one).to include("1 senator voted against their party.")
      expect(two).to include("2 members voted against their party.")
    end

    it "leaves out a Motion Introduction that was only \"I move:\"" do
      rendered = compile_summary(senate_data, template_id: 2, declines_second_reading: false, introduction: "I move:",
                                              motion_text: "At the end of the motion, add words.")

      expect(rendered).not_to include("### Motion Introduction")
      expect(rendered).to include("### Amendment Text")
    end

    it "keeps a Motion Introduction that says more than that" do
      rendered = compile_summary(senate_data, template_id: 2, declines_second_reading: false,
                                              introduction: "I move the second reading amendment on sheet 9001:",
                                              motion_text: "At the end of the motion, add words.")

      expect(rendered).to include("### Motion Introduction\n\n> I move the second reading amendment on sheet 9001:")
    end

    it "says the bill passed without a second \"This means\"" do
      rendered = compile_summary(senate_data, template_id: 6, motion_text: "That the remaining stages of the bill be agreed to.")

      expect(rendered).not_to include("This means the bill")
    end

    it "names the chamber that agreed to the second reading" do
      rendered = compile_summary(senate_data, template_id: 29, motion_text: "That this bill be now read a second time.")

      expect(rendered).to include("This means the Senate agreed with the main idea of the bill")
    end
  end

  describe "Template 2's explainer in each chamber" do
    it "gives the House's one precedent for a House division, and says nothing borrowed for the Senate" do
      house = compile_summary({ house: "representatives", result: "negatived" }, template_id: 2, declines_second_reading: false,
                                                                                 motion_text: "At the end of the motion, add words.")
      senate = compile_summary({ house: "senate", result: "negatived" }, template_id: 2, declines_second_reading: false,
                                                                         motion_text: "At the end of the motion, add words.")

      expect(house).to include("The House's Guide to Procedures (2017) records it happening once, in 2016")
      expect(senate).not_to include("carried in the House", "2016")
      expect(senate).to include("or to delay further consideration of it.*")
    end
  end

  describe "sections quoting Hansard" do
    let(:senate_data) { { time: "01:31 PM", amount: "majority", result: "passed", house: "senate" } }
    let(:treloar) { DivisionSummaryPipeline::MemberResolver.named("Morgan Treloar") }

    def section(rendered, heading)
      rendered[/^### #{Regexp.escape(heading)}\n\n(.*?)(?=\n\n### |\z)/m, 1]
    end

    describe "the separator after the explainer" do
      def required_facts(template_id)
        {
          9 => { regulation_name: "Example Instrument 2026" },
          10 => { target_name: "Fictional Member" },
          13 => { committee_name: "Economics References Committee" },
          19 => { rearrangement_description: "That the debate be adjourned." },
          20 => { business_name: "general business notice of motion no. 12" },
          23 => { target_name: "Fictional Member" },
          24 => { target_name: "Fictional Member" }
        }.fetch(template_id, {})
      end

      DivisionSummaryPipeline::TemplateCatalogue::IDS.each do |template_id|
        it "puts a line of --- between the explainer and the vote sentence in Template #{template_id}" do
          data = { time: "10:15 AM", amount: "majority", result: "passed", house: "representatives",
                   bill_name: "Example Bill 2026", mover_name: "Fictional Member" }
          rendered = compile_summary(
            data,
            template_id: template_id,
            declines_second_reading: false,
            motion_text: "That the motion be agreed to.",
            question_text: "The question is that the motion be agreed to.",
            facts: required_facts(template_id)
          )
          lines = rendered.lines(chomp: true)
          separator = lines.index("---")

          expect(lines.count("---")).to eq(1)
          expect(lines.first).to match(/\A\*\*(?:Bill Timeline|Jargon Explainer):\*\* /)
          # A blank line either side, or Markdown reads the paragraph above as a heading.
          expect(lines[separator - 1]).to eq("")
          expect(lines[separator + 1]).to eq("")
          expect(lines[separator + 2]).to start_with("At 10:15 AM, ")
        end
      end
    end

    describe "the mover's explanation" do
      it "quotes each passage under the time of the speech and the mover's name" do
        rendered = compile_summary(
          senate_data,
          template_id: 15,
          motion_text: "That the Senate notes the report.",
          explanations: ["The report sets out the costs plainly."],
          mover: treloar
        )

        expect(section(rendered, "About the Motion")).to eq(
          "At 1:27 PM, Senator Morgan Treloar said:\n\n> The report sets out the costs plainly."
        )
      end

      it "says so in a fixed sentence when there is nothing to quote" do
        rendered = compile_summary(
          senate_data,
          template_id: 15,
          motion_text: "That the Senate notes the report.",
          mover: treloar
        )

        expect(section(rendered, "About the Motion")).to eq("> No explanatory claims recorded.")
      end

      it "prints one header over two passages from the same speech" do
        rendered = compile_summary(
          senate_data,
          template_id: 15,
          motion_text: "That the Senate notes the report.",
          explanations: ["The report sets out the costs plainly.", "It deserves a response from the Government."],
          mover: treloar
        )

        expect(section(rendered, "About the Motion")).to eq(
          "At 1:27 PM, Senator Morgan Treloar said:\n\n> The report sets out the costs plainly.\n\n" \
          "> It deserves a response from the Government."
        )
        expect(rendered.scan("said:").size).to eq(1)
      end

      [22, 23, 24, 26].each do |template_id|
        it "prints no explanation section at all in Template #{template_id}" do
          rendered = compile_summary(
            senate_data,
            template_id: template_id,
            motion_text: "That the motion be agreed to.",
            explanations: ["This sentence is never printed."],
            facts: { target_name: "Fictional Member" },
            mover: treloar
          )

          expect(rendered).not_to include("said:")
          expect(rendered).not_to include("This sentence is never printed.")
          expect(rendered).not_to include("No explanatory claims recorded.")
        end
      end
    end

    describe "the question put" do
      it "quotes the chair's question under the time and the chair's name" do
        rendered = compile_summary(
          senate_data,
          template_id: 15,
          motion_text: "That the Senate notes the report.",
          question_text: "The question is that the motion be agreed to."
        )

        expect(section(rendered, "Question Put")).to eq(
          "At 1:30 PM, Senator Robin Castellan, in the chair, put the following question:\n\n" \
          "> The question is that the motion be agreed to."
        )
      end

      it "says so in a fixed sentence when no question was recorded" do
        rendered = compile_summary(senate_data, template_id: 15, motion_text: "That the Senate notes the report.")

        expect(section(rendered, "Question Put")).to eq("> No question was recorded before the division.")
      end
    end

    describe "the motion introduction" do
      it "quotes the mover's own words moving it" do
        rendered = compile_summary(
          senate_data,
          template_id: 15,
          motion_text: "That the Senate notes the report.",
          introduction: "I move the motion standing in my name."
        )

        expect(section(rendered, "Motion Introduction")).to eq("> I move the motion standing in my name.")
      end

      it "says so in a fixed sentence when none was recorded" do
        rendered = compile_summary(senate_data, template_id: 15, motion_text: "That the Senate notes the report.")

        expect(section(rendered, "Motion Introduction")).to eq("> No motion introduction recorded.")
      end
    end

    describe "the line attributing the motion" do
      it "credits the mover with the amendment in Template 2" do
        rendered = compile_summary(
          senate_data,
          template_id: 2,
          declines_second_reading: false,
          mover: treloar,
          motion_text: "That all words after \"That\" be omitted."
        )

        expect(section(rendered, "Amendment Text")).to eq(
          "Senator Morgan Treloar moved the following amendment:\n\n> That all words after \"That\" be omitted."
        )
      end

      it "credits the mover with the motion in Template 15" do
        rendered = compile_summary(
          senate_data,
          template_id: 15,
          motion_text: "That the Senate notes the report.",
          mover: treloar
        )

        expect(section(rendered, "Motion Text")).to eq(
          "Senator Morgan Treloar moved the following motion:\n\n> That the Senate notes the report."
        )
      end

      # The speech a model-found motion sits in may be the chair reading out someone else's
      # proposal, so it is not credited to the mover.
      it "credits nobody with a motion the model found rather than Stage 1" do
        interpretation, evidence = summary_inputs(template_id: 15, mover: treloar)
        evidence = evidence.with(motion: summary_excerpt("That the Senate notes the report.", found_by: :model))

        rendered = described_class.compile(senate_data, interpretation, evidence)

        expect(section(rendered, "Motion Text")).to eq(
          "The following motion was moved:\n\n> That the Senate notes the report."
        )
      end
    end

    describe "quotes are printed whole" do
      it "never trims or tidies a long motion" do
        paragraphs = ["That the Senate:"] + (1..12).map do |n|
          "(#{n}) notes  that the the Example Services Review, in its finding number #{n}, recommended that the " \
            "Government  consult the the peak bodies before changing the scheme, and that the Government has not " \
            "yet done so;"
        end
        motion = "#{paragraphs.join("\n\n")}\n\n(13) calls on the Government to respond before the end of the year."
        quoted = motion.gsub(/^(?=.)/, "> ").gsub(/^$/, ">")

        rendered = compile_summary(senate_data, template_id: 15, motion_text: motion, mover: treloar)

        expect(motion.length).to be > 2000
        expect(section(rendered, "Motion Text")).to eq("Senator Morgan Treloar moved the following motion:\n\n#{quoted}")
      end
    end

    describe "#fallbacks" do
      def fallbacks_for(data = senate_data, digest_section: nil, **inputs)
        compiler = described_class.new
        compiler.compile(data, *summary_inputs(**inputs), digest_section: digest_section)
        compiler.fallbacks
      end

      let(:motion) { "That the motion be agreed to." }
      let(:third_reading) { "That this bill be now read a third time." }

      it "records no explanation only for a template that quotes one" do
        expect(fallbacks_for(template_id: 15, motion_text: motion)).to include(:no_explanation)
        expect(fallbacks_for(template_id: 15, motion_text: motion, explanations: ["Said."])).not_to include(:no_explanation)
        expect(fallbacks_for(template_id: 22, motion_text: "That the question be now put.")).not_to include(:no_explanation)
      end

      it "records no question when the chair's question was not recorded" do
        question = "The question is that the motion be agreed to."

        expect(fallbacks_for(template_id: 15, motion_text: motion)).to include(:no_question)
        expect(fallbacks_for(template_id: 15, motion_text: motion, question_text: question)).not_to include(:no_question)
      end

      it "records an unresolved mover only when neither the division data nor Stage 1 names one" do
        supplied = senate_data.merge(mover_name: "Sam Taylor")

        expect(fallbacks_for(template_id: 15, motion_text: motion)).to include(:mover_unresolved)
        expect(fallbacks_for(template_id: 15, motion_text: motion, mover: treloar)).not_to include(:mover_unresolved)
        expect(fallbacks_for(supplied, template_id: 15, motion_text: motion)).not_to include(:mover_unresolved)
      end

      it "records no digest when a bill template has no Bills Digest to print" do
        digest = "According to the Bill Digest:\n\n> * It does a thing."

        expect(fallbacks_for(template_id: 6, motion_text: third_reading)).to include(:no_digest)
        expect(fallbacks_for(template_id: 6, motion_text: third_reading, digest_section: digest)).not_to include(:no_digest)
      end

      # ReviewerReport tells the reviewer "No Bill Digest found." is printed, which is only
      # true of the templates with an About the Bill section.
      it "does not record a missing digest for a template that prints no digest section" do
        expect(fallbacks_for(template_id: 15, motion_text: motion)).not_to include(:no_digest)
      end

      # The About the Bill section is what makes a template a bill template, so the reviewer is
      # told about a missing bill record on every one of them and on nothing else.
      it "records a missing bill record for every template with an About the Bill section, and only those" do
        bill_templates = DivisionSummaryPipeline::TemplateCatalogue::IDS.select do |id|
          File.read(Dir.glob(File.join(described_class::DEFAULT_TEMPLATES_DIR, "#{id}_*.md")).first)
              .include?("{{digest_section}}")
        end

        expect(bill_templates).to include(1, 2, 6, 7, 28, 29)
        expect(fallbacks_for(template_id: 29, motion_text: "That this bill be now read a second time."))
          .to include(:no_bill_record)
        expect(fallbacks_for(senate_data.merge(bill_name: "Example Bill 2026"), template_id: 6, motion_text: third_reading))
          .not_to include(:no_bill_record)
        expect(fallbacks_for(template_id: 15, motion_text: motion)).not_to include(:no_bill_record)
      end
    end
  end
end
