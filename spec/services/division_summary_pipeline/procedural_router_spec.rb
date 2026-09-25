# frozen_string_literal: true

require "spec_helper"

describe DivisionSummaryPipeline::ProceduralRouter do
  describe ".route" do
    context "with immediate procedural traps" do
      it "traps Member No Longer Heard (Template 23)" do
        decision = described_class.route(
          speaker_question: "The question is that the honourable member for Fairview be no longer heard."
        )
        expect(decision.is_deterministic).to be(true)
        expect(decision.template_id).to eq(23)
        expect(decision.rule_name).to eq("MEMBER_NO_LONGER_HEARD")
      end

      it "traps Closure of Debate (Template 22)" do
        decision = described_class.route(
          speaker_question: "The question is that the question be now put."
        )
        expect(decision.is_deterministic).to be(true)
        expect(decision.template_id).to eq(22)
        expect(decision.rule_name).to eq("CLOSURE_OF_DEBATE")
      end

      it "traps Suspension of Standing Orders (Template 17)" do
        decision = described_class.route(
          speaker_question: "That so much of the standing and sessional orders be suspended..."
        )
        expect(decision.is_deterministic).to be(true)
        expect(decision.template_id).to eq(17)
        expect(decision.rule_name).to eq("SUSPENSION_OF_STANDING_ORDERS")
      end

      it "traps First Reading (Template 1)" do
        decision = described_class.route(
          speaker_question: "The question is that this bill be now read a first time."
        )
        expect(decision.is_deterministic).to be(true)
        expect(decision.template_id).to eq(1)
        expect(decision.rule_name).to eq("FIRST_READING")
      end

      it "traps Disallowance Motion (Template 9)" do
        decision = described_class.route(
          speaker_question: "The question is that the regulation be disallowed."
        )
        expect(decision.is_deterministic).to be(true)
        expect(decision.template_id).to eq(9)
        expect(decision.rule_name).to eq("DISALLOWANCE_MOTION")
      end

      it "traps Censure Motion (Template 10)" do
        decision = described_class.route(
          speaker_question: "The question is that the House censure the Minister for Health."
        )
        expect(decision.is_deterministic).to be(true)
        expect(decision.template_id).to eq(10)
        expect(decision.rule_name).to eq("CENSURE_MOTION")
      end

      it "traps a want of confidence motion as a censure motion (Template 10)" do
        decision = described_class.route(
          speaker_question: "The question is that the House expresses its want of confidence in the Minister for Veterans' Affairs."
        )
        expect(decision.is_deterministic).to be(true)
        expect(decision.template_id).to eq(10)
        expect(decision.rule_name).to eq("CENSURE_MOTION")
      end

      it "fences Member No Longer Heard (Template 23) when the chamber is the Senate, where the motion does not exist" do
        decision = described_class.route(
          speaker_question: "The question is that the honourable member for Fairview be no longer heard.",
          chamber: "Senate"
        )
        expect(decision.is_deterministic).to be(false)
        expect(decision.candidate_templates).to eq([23])
        expect(decision.rule_name).to eq("MEMBER_NO_LONGER_HEARD_CHAMBER_CONFLICT")
      end

      it "traps Member Be Further Heard (Template 23)" do
        decision = described_class.route(
          speaker_question: "The question is that the member be further heard."
        )
        expect(decision.is_deterministic).to be(true)
        expect(decision.template_id).to eq(23)
        expect(decision.rule_name).to eq("MEMBER_NO_LONGER_HEARD")
      end

      it "traps Suspension of a Member (Template 24)" do
        decision = described_class.route(
          speaker_question: "The question is that the member be suspended from the service of the House."
        )
        expect(decision.is_deterministic).to be(true)
        expect(decision.template_id).to eq(24)
        expect(decision.rule_name).to eq("SUSPENSION_OF_MEMBER")
      end

      it "traps Dissent from a Ruling of the Chair (Template 25)" do
        decision = described_class.route(
          speaker_question: "The question is that the Speaker's ruling be dissented from."
        )
        expect(decision.is_deterministic).to be(true)
        expect(decision.template_id).to eq(25)
        expect(decision.rule_name).to eq("DISSENT_FROM_RULING")
      end

      it "traps Adjournment of the Chamber (Template 26)" do
        decision = described_class.route(
          speaker_question: "The question is that the House do now adjourn."
        )
        expect(decision.is_deterministic).to be(true)
        expect(decision.template_id).to eq(26)
        expect(decision.rule_name).to eq("ADJOURNMENT_OF_CHAMBER")
      end

      it "traps Taking Note of a document or answer (Template 27)" do
        decision = described_class.route(
          speaker_question: "The question is that the House take note of the document."
        )
        expect(decision.is_deterministic).to be(true)
        expect(decision.template_id).to eq(27)
        expect(decision.rule_name).to eq("TAKE_NOTE")
      end

      it "traps Calling on the Business of the Day as a closure of debate (Template 22)" do
        decision = described_class.route(
          speaker_question: "The question is that the business of the day be called on."
        )
        expect(decision.is_deterministic).to be(true)
        expect(decision.template_id).to eq(22)
        expect(decision.rule_name).to eq("CLOSURE_OF_DEBATE")
      end

      it "routes an Order for the Production of Documents worded around papers (Template 8)" do
        decision = described_class.route(
          speaker_question: "The question is that there be laid upon the table the following papers."
        )
        expect(decision.is_deterministic).to be(true)
        expect(decision.template_id).to eq(8)
        expect(decision.rule_name).to eq("PRODUCTION_OF_DOCUMENTS")
      end
    end

    context "with guillotine trap avoidance" do
      it "locks out Template 18 when an amendment occurs under a Limitation of Debate heading" do
        decision = described_class.route(
          speaker_question: "The question is that the amendment moved by the member for Ryan be agreed to.",
          chamber: "House of Representatives",
          debate_heading: "Limitation of Debate"
        )
        expect(decision.is_deterministic).to be(false)
        expect(decision.locked_out_templates).to include(18)
        expect(decision.candidate_templates).to contain_exactly(2, 4)
        expect(decision.rule_name).to eq("GUILLOTINE_TRAP_AVOIDED")
      end

      it "routes to Template 18 when the question is on the guillotine procedure itself" do
        decision = described_class.route(
          speaker_question: "The question is that the time allotted for debate be limited.",
          debate_heading: "Limitation of Debate"
        )
        expect(decision.is_deterministic).to be(true)
        expect(decision.template_id).to eq(18)
        expect(decision.rule_name).to eq("GUILLOTINE_PROCEDURE")
      end
    end

    context "with nuanced stages" do
      it "identifies direct Second Reading Amendment (Template 2)" do
        decision = described_class.route(
          speaker_question: "The question is that the words proposed to be omitted (Mr Pyne's amendment) stand part of the question."
        )
        expect(decision.candidate_templates).to include(2)
      end

      it "fences ambiguous second reading questions between 2 and 6" do
        decision = described_class.route(
          speaker_question: "The question is that this bill be now read a second time."
        )
        expect(decision.is_deterministic).to be(false)
        expect(decision.candidate_templates).to contain_exactly(2, 6)
        expect(decision.rule_name).to eq("SECOND_READING_NUANCE")
      end

      it "routes postponing the second reading to Rearrangement of Business (Template 19), not the second reading rules" do
        decision = described_class.route(
          speaker_question: "The question is the second reading be made an order of the day for the next sitting."
        )
        expect(decision.is_deterministic).to be(true)
        expect(decision.template_id).to eq(19)
        expect(decision.rule_name).to eq("REARRANGEMENT_OF_BUSINESS")
      end

      it "routes an adjournment of debate motion to Rearrangement of Business (Template 19)" do
        decision = described_class.route(
          speaker_question: "The question is that the debate be adjourned till the next sitting."
        )
        expect(decision.is_deterministic).to be(true)
        expect(decision.template_id).to eq(19)
        expect(decision.rule_name).to eq("REARRANGEMENT_OF_BUSINESS")
      end

      it "locks Template 18 out of an ambiguous second reading under a Limitation of Debate heading" do
        decision = described_class.route(
          speaker_question: "The question is that this bill be now read a second time.",
          debate_heading: "Limitation of Debate"
        )
        expect(decision.is_deterministic).to be(false)
        expect(decision.candidate_templates).to contain_exactly(2, 6)
        expect(decision.locked_out_templates).to eq([18])
      end

      it "locks Template 18 out of the general motion fallback under a Limitation of Debate heading" do
        decision = described_class.route(
          speaker_question: "The question is that the report of the Audit Committee be adopted.",
          debate_heading: "Limitation of Debate"
        )
        expect(decision.rule_name).to eq("GENERAL_MOTION_FALLBACK")
        expect(decision.locked_out_templates).to eq([18])
      end

      it "marks the general motion fallback's candidate advisory, unlike a real fence" do
        fallback = described_class.route(
          speaker_question: "The question is that the report of the Audit Committee be adopted."
        )
        fenced = described_class.route(
          speaker_question: "The question is that the bill be read a second time."
        )

        expect(fallback.advisory_candidates).to be(true)
        expect(fenced.advisory_candidates).to be_falsey
      end

      it "routes Third Reading to passing a bill (Template 6)" do
        decision = described_class.route(
          speaker_question: "The question is that this bill be now read a third time."
        )
        expect(decision.is_deterministic).to be(true)
        expect(decision.template_id).to eq(6)
        expect(decision.rule_name).to eq("THIRD_READING_PASSING")
      end

      it "routes a 'stand as printed' question about part of a bill to Template 28" do
        decision = described_class.route(
          speaker_question: "The question is that the clause stand as printed.",
          chamber: "Senate"
        )
        expect(decision.is_deterministic).to be(true)
        expect(decision.template_id).to eq(28)
        expect(decision.rule_name).to eq("STAND_AS_PRINTED_OMISSION")
      end

      # "That the bill stand as printed" is the final question in committee of the whole when
      # no amendments have been agreed to, the counterpart of "That the bill, as amended, be
      # agreed to". It omits nothing, so it must not pick up Template 28's inversion.
      it "keeps 'that the bill stand as printed' away from Template 28" do
        decision = described_class.route(
          speaker_question: "The question is that the bill stand as printed.",
          chamber: "Senate"
        )
        expect(decision.template_id).not_to eq(28)
        expect(decision.candidate_templates).not_to include(28)
      end

      it "still reaches Template 28 under a Limitation of Debate heading" do
        decision = described_class.route(
          speaker_question: "The question is that Schedule 2 stand as printed.",
          chamber: "Senate",
          debate_heading: "Limitation of Debate"
        )
        expect(decision.candidate_templates).to eq([28])
        expect(decision.locked_out_templates).to include(18)
      end

      it "routes consideration of messages with disagreements or insistences to Template 7" do
        insist_decision = described_class.route(
          speaker_question: "The question is that the Senate insists on its amendments disagreed to by the House."
        )
        expect(insist_decision.is_deterministic).to be(true)
        expect(insist_decision.template_id).to eq(7)
        expect(insist_decision.rule_name).to eq("CONSIDERATION_OF_MESSAGE")

        request_decision = described_class.route(
          speaker_question: "The question is that the requested amendments be made."
        )
        expect(request_decision.is_deterministic).to be(true)
        expect(request_decision.template_id).to eq(7)
        expect(request_decision.rule_name).to eq("CONSIDERATION_OF_MESSAGE")
      end

      it "routes House Selection Committee determinations to Rearrangement of Business (Template 19)" do
        decision = described_class.route(
          speaker_question: "The question is that the report of the Selection Committee be adopted.",
          chamber: "House of Representatives"
        )
        expect(decision.is_deterministic).to be(true)
        expect(decision.template_id).to eq(19)
        expect(decision.rule_name).to eq("REARRANGEMENT_OF_BUSINESS")
      end

      it "routes Federation Chamber unresolved questions to Template 5" do
        decision = described_class.route(
          speaker_question: "The question is that the unresolved question reported from the Federation Chamber be agreed to."
        )
        expect(decision.is_deterministic).to be(true)
        expect(decision.template_id).to eq(5)
        expect(decision.rule_name).to eq("FEDERATION_CHAMBER_REPORT")
      end
    end

    # A suspension question quotes the motion it would enable ("That so much of the standing
    # orders be suspended as would prevent ..."), so it contains the trigger words of whichever
    # rule covers that motion. The suspension division decides only that the rules are set
    # aside; the thing it cleared the way for is a separate division if it happens at all.
    context "when a suspension question quotes the motion it would enable" do
      {
        "a member being further heard" => "the honourable member for Fairview being further heard",
        "a member's suspension" => "the member being suspended from the service of the House",
        "a dissent motion" => "a motion of dissent from the ruling of the Speaker being moved",
        "an adjournment motion" => "a motion that the House do now adjourn being moved",
        "a take note motion" => "the House taking note of the document",
        "a censure motion" => "me from moving a censure motion"
      }.each do |description, enabled_motion|
        it "routes a suspension enabling #{description} to Template 17" do
          decision = described_class.route(
            speaker_question: "That so much of the standing orders be suspended as would prevent #{enabled_motion}.",
            chamber: "House of Representatives"
          )
          expect(decision.template_id).to eq(17)
          expect(decision.rule_name).to eq("SUSPENSION_OF_STANDING_ORDERS")
        end
      end
    end

    # Two of the standard reasoned-amendment forms are "the bill be withdrawn and redrafted to
    # provide for ..." and "the bill be withdrawn and a select committee be appointed to inquire
    # into ...". Those are amendments to the second reading motion, not motions to withdraw
    # business from the Notice Paper.
    context "when a second reading amendment asks for a bill to be withdrawn" do
      it "routes it to Template 2 rather than Withdrawal of Business" do
        decision = described_class.route(
          speaker_question: "That all words after 'That' be omitted with a view to substituting the following words: " \
                            "'whilst not declining to give the bill a second reading, the House is of the opinion " \
                            "that the bill be withdrawn and redrafted to provide for adequate consultation'.",
          chamber: "House of Representatives"
        )
        expect(decision.template_id).to eq(2)
        expect(decision.rule_name).to eq("SECOND_READING_AMENDMENT_DIRECT")
      end

      it "leaves an amendment to withdraw a bill to the amendment stage rules" do
        decision = described_class.route(
          speaker_question: "The question is that the amendment, that the bill be withdrawn and redrafted, " \
                            "be agreed to.",
          chamber: "House of Representatives"
        )
        expect(decision.rule_name).not_to eq("WITHDRAWAL_OF_BUSINESS")
        expect(decision.candidate_templates).to eq([2, 4])
      end

      it "still routes a genuine withdrawal of business to Template 20" do
        decision = described_class.route(
          speaker_question: "The question is that general business notice of motion no. 4 be withdrawn.",
          chamber: "Senate"
        )
        expect(decision.template_id).to eq(20)
        expect(decision.rule_name).to eq("WITHDRAWAL_OF_BUSINESS")
      end
    end

    # A suspension question recites the motion it would clear the way for, so it carries the
    # trigger words of whichever rule covers that motion. ARCHITECTURE.md said the suspension
    # rule was matched first for that reason; the code checked the closure rule first.
    describe "suspension of standing orders is matched before the motion it would enable" do
      it "routes a suspension moved to let a question be put to Template 17, not Template 22" do
        decision = described_class.route(
          speaker_question: "The question is that so much of the standing orders be suspended as would " \
                            "prevent the question being now put on the motion moved by the Leader of the Opposition.",
          chamber: "House of Representatives"
        )

        expect(decision.template_id).to eq(17)
        expect(decision.rule_name).to eq("SUSPENSION_OF_STANDING_ORDERS")
      end

      it "routes a suspension moved to let a member be no longer heard to Template 17" do
        decision = described_class.route(
          speaker_question: "The question is that so much of the standing orders be suspended as would prevent " \
                            "a motion that the member for Fairview be no longer heard.",
          chamber: "House of Representatives"
        )

        expect(decision.template_id).to eq(17)
      end

      it "still routes a plain closure to Template 22" do
        decision = described_class.route(
          speaker_question: "The question is that the question be now put.",
          chamber: "House of Representatives"
        )

        expect(decision.template_id).to eq(22)
        expect(decision.rule_name).to eq("CLOSURE_OF_DEBATE")
      end
    end

    # The House guillotine is two questions, not one (S.O.s 82-84). Only the second was
    # routed, so the first fell to Template 15 and was described as an opinion-only motion.
    describe "the declaration of urgency that starts a House guillotine" do
      it "routes 'That the bill be considered urgent' to Template 18" do
        decision = described_class.route(
          speaker_question: "The question is that the bill be considered urgent.",
          chamber: "House of Representatives"
        )

        expect(decision.template_id).to eq(18)
        expect(decision.rule_name).to eq("GUILLOTINE_PROCEDURE")
        expect(decision.reason).to include("declares the bill urgent")
      end

      it "routes an allotment of time to Template 18" do
        decision = described_class.route(
          speaker_question: "The question is that the allotment of time for the bill be agreed to.",
          chamber: "House of Representatives"
        )

        expect(decision.template_id).to eq(18)
      end

      # The keyword collision the catalogue warns about: a Senate matter of urgency is a
      # different procedure and must keep its own template.
      it "does not confuse a Senate matter of urgency with a declaration of urgency" do
        decision = described_class.route(
          speaker_question: "The question is that in the opinion of the Senate the following is a matter of " \
                            "urgency: the cost of living.",
          chamber: "Senate"
        )

        expect(decision.template_id).to eq(16)
      end
    end

    describe "the closure used during the election of a Speaker" do
      it "routes 'That the ballot be taken now' to Template 22" do
        decision = described_class.route(
          speaker_question: "The question is that the ballot be taken now.",
          chamber: "House of Representatives"
        )

        expect(decision.template_id).to eq(22)
        expect(decision.reason).to include("election of the Speaker")
      end
    end
  end
end
