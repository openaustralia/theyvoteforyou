# frozen_string_literal: true

require "spec_helper"

describe AiDivisionSummary do
  describe "validations" do
    it "requires a model" do
      summary = build(:ai_division_summary, model: nil)
      expect(summary).not_to be_valid
    end
  end

  describe ".save_from_result!" do
    it "maps every field from the summarizer's result" do
      division = create(:division)
      result = DivisionSummarizer::Result.new(
        model: "test.model-v1:0",
        title: "Motions — Coal Seam Gas",
        description: "The Senate voted on a motion about coal seam gas.",
        raw: '{"title": "Motions — Coal Seam Gas"}',
        system_prompt: "You are the Evidence Selector.",
        user_prompt: "<speaker_question>The question is that the motion be agreed to.</speaker_question>"
      )

      summary = described_class.save_from_result!(division, result)

      expect(summary.division).to eq division
      expect(summary.model).to eq "test.model-v1:0"
      expect(summary.title).to eq "Motions — Coal Seam Gas"
      expect(summary.description).to eq "The Senate voted on a motion about coal seam gas."
      expect(summary.raw_response).to eq '{"title": "Motions — Coal Seam Gas"}'
      expect(summary.system_prompt).to eq "You are the Evidence Selector."
      expect(summary.user_prompt).to start_with "<speaker_question>"
      expect(summary.error).to be_nil
    end

    # A sitting day prompt ran to 104,305 bytes and a guillotine draft to 50,610, against the
    # 65,535 a MySQL TEXT column holds.
    it "keeps a prompt and a draft longer than a TEXT column holds" do
      long = "x" * 100_000
      result = DivisionSummarizer::Result.new(model: "test.model-v1:0", title: "A title", description: long,
                                              user_prompt: long)

      summary = described_class.save_from_result!(create(:division), result).reload

      expect(summary.description.size).to eq 100_000
      expect(summary.user_prompt.size).to eq 100_000
    end

    it "records an error instead of a title/description when the model fails" do
      division = create(:division)
      result = DivisionSummarizer::Result.new(model: "test.model-v1:0", error: "boom")

      summary = described_class.save_from_result!(division, result)

      expect(summary.error).to eq "boom"
      expect(summary.title).to be_nil
    end

    it "overwrites a failed attempt rather than raising on the unique index" do
      division = create(:division)
      described_class.create!(division: division, model: "test.model-v1:0", error: "ServiceUnavailable")
      result = DivisionSummarizer::Result.new(model: "test.model-v1:0", title: "A title", description: "A description.")

      summary = described_class.save_from_result!(division, result)

      expect(summary.error).to be_nil
      expect(summary.title).to eq "A title"
      expect(described_class.where(division: division, model: "test.model-v1:0").count).to eq 1
    end
  end
end
