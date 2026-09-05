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
      suggestion = build(:ai_policy_suggestion, match: "existing", direction: "for", policy: build(:policy, id: 42, name: "marriage equality"))
      expect(suggestion.summary).to eq "For policy 42 (marriage equality)"
    end

    it "says so when the matched policy has since been deleted" do
      policy = create(:policy)
      suggestion = create(:ai_policy_suggestion, match: "existing", direction: "against", policy: policy)

      policy.destroy!

      expect(suggestion.reload.summary).to eq "Against a policy that has since been deleted"
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

  describe "#error?" do
    it "is true when the error column is set" do
      suggestion = build(:ai_policy_suggestion, error: "boom")
      expect(suggestion.error?).to be true
    end

    it "is true when match/direction are missing, even without an error column" do
      suggestion = build(:ai_policy_suggestion, match: nil, direction: nil, error: nil)
      expect(suggestion.error?).to be true
    end

    it "is false for a normal classification" do
      suggestion = build(:ai_policy_suggestion, match: "existing", direction: "for", error: nil)
      expect(suggestion.error?).to be false
    end

    it "agrees with #summary on a blank error, treating it as no error at all" do
      suggestion = build(:ai_policy_suggestion, match: "existing", direction: "for", error: "")

      expect(suggestion.error?).to be false
      expect(suggestion.summary).not_to start_with "Error:"
    end
  end
end
