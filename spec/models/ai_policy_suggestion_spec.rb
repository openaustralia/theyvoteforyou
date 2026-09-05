# frozen_string_literal: true

require "spec_helper"

describe AiPolicySuggestion do
  describe "validations" do
    it "requires a model" do
      suggestion = build(:ai_policy_suggestion, model: nil)
      expect(suggestion).not_to be_valid
    end

    it "allows match and direction to be nil, for a failed classification" do
      suggestion = build(:ai_policy_suggestion, match: nil, direction: nil)
      expect(suggestion).to be_valid
    end

    it "rejects a match value that isn't existing or new" do
      suggestion = build(:ai_policy_suggestion, match: "sort-of")
      expect(suggestion).not_to be_valid
    end

    it "rejects a direction value that isn't for or against" do
      suggestion = build(:ai_policy_suggestion, direction: "sideways")
      expect(suggestion).not_to be_valid
    end
  end

  describe ".create_from_result!" do
    it "maps every field from the classifier's result" do
      division = create(:division)
      policy = create(:policy)
      result = DivisionPolicyClassifier::Result.new(
        model: "test.model-v1:0",
        match: "existing",
        policy: policy,
        direction: "for",
        reasoning: "because",
        raw: '{"match": "existing"}'
      )

      suggestion = described_class.create_from_result!(division, result)

      expect(suggestion.division).to eq division
      expect(suggestion.policy).to eq policy
      expect(suggestion.model).to eq "test.model-v1:0"
      expect(suggestion.match).to eq "existing"
      expect(suggestion.direction).to eq "for"
      expect(suggestion.reasoning).to eq "because"
      expect(suggestion.raw_response).to eq '{"match": "existing"}'
    end
  end

  describe "#summary" do
    it "names the matched policy and direction" do
      suggestion = build(:ai_policy_suggestion, match: "existing", direction: "for", policy: build(:policy, id: 42))
      expect(suggestion.summary).to eq "For policy 42"
    end

    it "says a new policy was proposed" do
      suggestion = build(:ai_policy_suggestion, match: "new", direction: "against", policy: nil)
      expect(suggestion.summary).to eq "Against new policy I propose"
    end

    it "reports the stored error instead of guessing" do
      suggestion = build(:ai_policy_suggestion, error: "boom")
      expect(suggestion.summary).to eq "Error: boom"
    end

    it "reports an error rather than a misleading summary when match/direction are missing" do
      suggestion = build(:ai_policy_suggestion, match: nil, direction: nil, error: nil)
      expect(suggestion.summary).to eq "Error: model response was missing match/direction"
    end
  end
end
