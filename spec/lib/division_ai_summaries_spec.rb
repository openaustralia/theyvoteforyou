# frozen_string_literal: true

require "spec_helper"

describe DivisionAiSummaries do
  let(:division) { create(:division) }
  let(:rows) { described_class.new(division).to_a }

  it "has a row for each model it can label, drafted or not" do
    expect(rows.map(&:label)).to eq(DivisionPolicyClassifier::MODEL_LABELS.values)
    expect(rows).to all(have_attributes(drafted?: false))
  end

  it "adds a row for each uploaded draft, labelled with its model and who uploaded it" do
    uploader = create(:confirmed_user, name: "Example Admin", admin: true)
    ingest = Ingest.create!(kind: "division-summary", user: uploader, status: "done")
    AiDivisionSummary.create!(division: division, model: "local.Example-Q4", title: "T", description: "D", ingest: ingest)

    row = rows.last
    expect(row).to have_attributes(label: "local.Example-Q4 (uploaded by Example Admin)", title: "T", drafted?: true)
  end

  it "still hides a draft from a retired model that was not uploaded" do
    AiDivisionSummary.create!(division: division, model: "retired.model", title: "T", description: "D")
    expect(rows.map(&:label)).to eq(DivisionPolicyClassifier::MODEL_LABELS.values)
  end
end
