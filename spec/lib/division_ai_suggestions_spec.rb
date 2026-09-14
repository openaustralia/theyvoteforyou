# frozen_string_literal: true

require "spec_helper"

describe DivisionAiSuggestions do
  subject(:panel) { described_class.new(division) }

  let(:division) { create(:division) }
  let(:policy) { create(:policy, name: "marriage equality") }
  let(:model_ids) { DivisionPolicyClassifier::MODEL_LABELS.keys }

  def rows
    panel.each.to_a
  end

  def suggest(model_id, **attributes)
    create(:ai_policy_suggestion, { division: division, model: model_id }.merge(attributes))
  end

  describe "#any?" do
    it "is false when no model has classified the division" do
      expect(panel.any?).to be false
    end

    it "is true once a model has" do
      suggest(model_ids.first, policy: policy)
      expect(panel.any?).to be true
    end

    it "ignores suggestions from models the panel can't label" do
      suggest("retired.model-v1", policy: policy)
      expect(panel.any?).to be false
    end
  end

  describe "#each" do
    it "yields a row per model the panel knows about, whether or not it has run" do
      suggest(model_ids.first, policy: policy)

      expect(rows.map(&:label)).to eq DivisionPolicyClassifier::MODEL_LABELS.values
      expect(rows.first).not_to be_unclassified
      expect(rows.last).to be_unclassified
    end
  end

  describe "agreement" do
    it "counts models that matched the same policy in the same direction" do
      model_ids.first(2).each { |id| suggest(id, policy: policy, direction: "for") }
      suggest(model_ids.last, policy: policy, direction: "against")

      expect(rows.map(&:agree_count)).to eq [2, 2, 1]
      expect(rows.first).to be_agreement
      expect(rows.last).not_to be_agreement
    end

    it "doesn't treat suggestions naming no policy as agreeing with each other" do
      model_ids.each { |id| suggest(id, policy: policy, direction: "for") }
      policy.destroy!

      expect(rows.map(&:agree_count)).to eq [0, 0, 0]
    end
  end

  describe "already-linked state" do
    before { model_ids.each { |id| suggest(id, policy: policy, direction: "for") } }

    it "reports a connection recorded in the same direction" do
      create(:policy_division, division: division, policy: policy, vote: "aye")

      expect(rows.first).to be_linked_same_way
      expect(rows.first).not_to be_linked_other_way
    end

    it "reports a connection recorded the other way, strong votes included" do
      create(:policy_division, division: division, policy: policy, vote: "no3")

      expect(rows.first).to be_linked_other_way
      expect(rows.first).not_to be_linked_same_way
    end

    it "reports neither when nothing is linked" do
      expect(rows.first).not_to be_linked_same_way
      expect(rows.first).not_to be_linked_other_way
    end
  end

  describe "#unanimous" do
    it "names the policy and direction when every model agrees" do
      model_ids.each { |id| suggest(id, policy: policy, direction: "against") }

      expect(panel.unanimous.policy).to eq policy
      expect(panel.unanimous.direction).to eq "against"
      expect(panel.unanimous.vote).to eq "no"
    end

    it "translates a for direction into an aye vote" do
      model_ids.each { |id| suggest(id, policy: policy, direction: "for") }

      expect(panel.unanimous.vote).to eq "aye"
    end

    it "is nil when only some of the models agree" do
      model_ids.first(2).each { |id| suggest(id, policy: policy, direction: "for") }
      suggest(model_ids.last, policy: policy, direction: "against")

      expect(panel.unanimous).to be_nil
    end

    it "is nil when the division is already linked to that policy" do
      model_ids.each { |id| suggest(id, policy: policy, direction: "for") }
      create(:policy_division, division: division, policy: policy, vote: "aye")

      expect(panel.unanimous).to be_nil
    end

    it "is nil when an unknown model makes up the numbers" do
      model_ids.first(2).each { |id| suggest(id, policy: policy, direction: "for") }
      suggest("retired.model-v1", policy: policy, direction: "for")

      expect(panel.unanimous).to be_nil
    end
  end

  describe "row css_class" do
    it "names the outcome, or says the model hasn't run" do
      suggest(model_ids.first, policy: policy, match: "existing")
      suggest(model_ids[1], policy: nil, match: "new")
      suggest(model_ids.last, policy: policy, match: nil, direction: nil)

      expect(rows.map(&:css_class)).to eq %w[
        ai-policy-suggestion-existing
        ai-policy-suggestion-new
        ai-policy-suggestion-error
      ]
    end

    it "says unclassified for a model that hasn't run" do
      suggest(model_ids.first, policy: policy)

      expect(rows.last.css_class).to eq "ai-policy-suggestion-unclassified"
    end
  end
end
