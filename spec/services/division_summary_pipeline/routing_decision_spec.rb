# frozen_string_literal: true

require "spec_helper"

describe DivisionSummaryPipeline::RoutingDecision do
  describe "#refuses?" do
    it "refuses anything but the settled template" do
      decision = described_class.settled(17, rule_name: "EXAMPLE", reason: "Example.")

      expect(decision.refuses?(17)).to be(false)
      expect(decision.refuses?(15)).to be(true)
    end

    it "refuses anything outside a fence, and a forbidden template inside it" do
      decision = described_class.fenced([2, 6, 18], rule_name: "EXAMPLE", reason: "Example.", forbidden: [18])

      expect(decision.refuses?(6)).to be(false)
      expect(decision.refuses?(4)).to be(true)
      expect(decision.refuses?(18)).to be(true)
    end

    it "lets the extractor depart from an advisory default, but never to a forbidden template" do
      decision = described_class.default([15], rule_name: "EXAMPLE", reason: "Example.", forbidden: [18])

      expect(decision.refuses?(15)).to be(false)
      expect(decision.refuses?(10)).to be(false)
      expect(decision.refuses?(18)).to be(true)
    end

    it "refuses only forbidden templates when a fence names no templates" do
      decision = described_class.fenced([], rule_name: "EXAMPLE", reason: "Example.", forbidden: [18])

      expect(decision.refuses?(10)).to be(false)
      expect(decision.refuses?(18)).to be(true)
    end
  end
end
