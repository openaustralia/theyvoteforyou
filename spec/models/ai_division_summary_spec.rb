# frozen_string_literal: true

require "spec_helper"

describe AiDivisionSummary do
  describe "validations" do
    it "requires a model" do
      summary = build(:ai_division_summary, model: nil)
      expect(summary).not_to be_valid
    end
  end

  it "holds one draft per division and model" do
    draft = create(:ai_division_summary)

    expect { described_class.create!(division: draft.division, model: draft.model) }
      .to raise_error(ActiveRecord::RecordNotUnique)
  end

  # A sitting day prompt ran to 104,305 bytes and a guillotine draft to 50,610, against the
  # 65,535 a MySQL TEXT column holds.
  it "keeps a description and a prompt longer than a TEXT column holds" do
    long = "x" * 100_000
    summary = create(:ai_division_summary, description: long, user_prompt: long).reload

    expect(summary.description.size).to eq 100_000
    expect(summary.user_prompt.size).to eq 100_000
  end

  it "belongs to the upload it arrived in, when it came from one" do
    ingest = Ingest.create!(kind: "division-summary")

    expect(create(:ai_division_summary, ingest: ingest).ingest).to eq ingest
    expect(create(:ai_division_summary, model: "other").ingest).to be_nil
  end
end
