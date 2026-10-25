# frozen_string_literal: true

require "spec_helper"

describe DivisionSummaryPipeline::ContextPacket do
  def packet(question)
    described_class.new(facts: nil, heading: "", speaker_question: question, transcript: nil, mover: nil, routing: nil,
                        context_level: :subdebate, context_warnings: [], source: :hansard_xml, division_xml_id: nil,
                        limitation_statement: nil)
  end

  describe "#question_by_reference?" do
    # KI-44: the government's sheets carry letters, so a question on them
    # was not recognised as referring to terms it did not state.
    it "is true for a question on amendments by their sheet, however the sheet is named" do
      ["The question is that the amendment on sheet 9001 be agreed to.",
       "The question is that the amendments on sheets 9101, 9102 and 9103 be agreed to.",
       "The question now is that amendments (1) to (6) on sheet XY128 and amendments (1) to (3) on sheet QZ116 revised " \
       "be agreed to."].each do |question|
        expect(packet(question)).to be_question_by_reference, question
      end
    end

    it "is false for a question that states its own terms" do
      expect(packet("The question is that the remaining stages of the bill be agreed to and the bill be now passed."))
        .not_to be_question_by_reference
    end
  end
end
