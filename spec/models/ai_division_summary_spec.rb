# frozen_string_literal: true

require "spec_helper"

describe AiDivisionSummary do
  describe "validations" do
    it "requires a model" do
      summary = build(:ai_division_summary, model: nil)
      expect(summary).not_to be_valid
    end
  end

  describe ".create_from_result!" do
    it "maps every field from the summarizer's result" do
      division = create(:division)
      result = DivisionSummarizer::Result.new(
        model: "test.model-v1:0",
        title: "Motions — Coal Seam Gas",
        description: "The Senate voted on a motion about coal seam gas.",
        raw: '{"title": "Motions — Coal Seam Gas"}'
      )

      summary = described_class.create_from_result!(division, result)

      expect(summary.division).to eq division
      expect(summary.model).to eq "test.model-v1:0"
      expect(summary.title).to eq "Motions — Coal Seam Gas"
      expect(summary.description).to eq "The Senate voted on a motion about coal seam gas."
      expect(summary.raw_response).to eq '{"title": "Motions — Coal Seam Gas"}'
      expect(summary.error).to be_nil
    end

    it "records an error instead of a title/description when the model fails" do
      division = create(:division)
      result = DivisionSummarizer::Result.new(model: "test.model-v1:0", error: "boom")

      summary = described_class.create_from_result!(division, result)

      expect(summary.error).to eq "boom"
      expect(summary.title).to be_nil
    end
  end
end
