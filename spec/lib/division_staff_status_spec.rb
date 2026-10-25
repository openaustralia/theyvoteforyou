# frozen_string_literal: true

require "spec_helper"

describe DivisionStaffStatus do
  subject(:status) { described_class.new(division).to_h { |item| [item.label, item.done?] } }

  let(:division) { create(:division) }

  it "reports nothing done for a bare division" do
    expect(status.values).to all(be false)
  end

  it "reports AI summary drafts but ignores errored ones" do
    AiDivisionSummary.create!(division: division, model: "a", title: "T", description: "D")
    AiDivisionSummary.create!(division: division, model: "b", error: "boom")
    expect(status["AI summary drafts"]).to be true
    expect(status["Summary"]).to be false
  end

  it "reports AI policy drafts" do
    AiPolicySuggestion.create!(division: division, model: "a", match: "new", direction: "for")
    expect(status["AI policy drafts"]).to be true
  end

  it "reports a linked policy" do
    create(:policy_division, division: division)
    expect(described_class.new(division.reload).to_h { |i| [i.label, i.done?] }["Policy"]).to be true
  end
end
