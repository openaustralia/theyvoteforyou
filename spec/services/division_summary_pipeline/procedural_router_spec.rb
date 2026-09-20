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
    end
  end
end

