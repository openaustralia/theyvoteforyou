# frozen_string_literal: true

# Assembles what the division page's staff-only AI suggestions panel needs: one Row per model the
# classifier knows how to label, and whether the models unanimously landed on a policy the division
# isn't linked to yet. It decides nothing about classification itself - that's
# DivisionPolicyClassifier writing AiPolicySuggestion records - it only works out how those records
# sit against each other and against the connections a human has already made.
class DivisionAiSuggestions
  # The models agreed on this policy and direction, and nothing links the division to it yet.
  Unanimous = Struct.new(:policy, :direction, keyword_init: true) do
    # PolicyDivision stores a vote, not a direction: a supporter of a "for" policy votes aye.
    def vote
      direction == "for" ? "aye" : "no"
    end
  end

  delegate :any?, to: :suggestions

  def initialize(division)
    @division = division
  end

  def model_count
    known_models.size
  end

  def each(&)
    known_models.map { |model_id, label| Row.new(self, label, suggestions[model_id]) }.each(&)
  end

  # nil unless every model matched the same existing policy in the same direction, and that policy
  # isn't already linked - the one case the panel offers to act on in a single click.
  def unanimous
    return @unanimous if defined?(@unanimous)

    @unanimous = build_unanimous
  end

  def agree_count(suggestion)
    agreement[[suggestion.policy_id, suggestion.direction]].to_i
  end

  def linked_vote(suggestion)
    linked_votes[suggestion.policy_id]
  end

  private

  attr_reader :division

  def known_models
    DivisionPolicyClassifier::MODEL_LABELS
  end

  # Only models the panel can label: a suggestion left over from a model id since retired from
  # MODEL_LABELS shouldn't count towards agreement nobody can see it taking part in.
  def suggestions
    @suggestions ||= division.ai_policy_suggestions
                             .includes(:policy)
                             .index_by(&:model)
                             .slice(*known_models.keys)
  end

  # policy_id is nil both for new-policy proposals and for matches whose policy can no longer be
  # found, so it can't stand in for "these two agree" - only real classifications naming a policy
  # are counted.
  def agreement
    @agreement ||= suggestions.values
                              .reject(&:error?)
                              .select { |s| s.match == "existing" && s.policy_id }
                              .group_by { |s| [s.policy_id, s.direction] }
                              .transform_values(&:size)
  end

  def linked_votes
    @linked_votes ||= division.policy_divisions.pluck(:policy_id, :vote).to_h
  end

  def build_unanimous
    policy_id, direction = agreement.key(model_count)
    return if policy_id.nil? || linked_votes.key?(policy_id)

    policy = suggestions.values.find { |s| s.policy_id == policy_id }&.policy
    Unanimous.new(policy: policy, direction: direction) if policy
  end

  # One model's row: its label, what it came back with (if anything), and how that sits against the
  # other models and against what's already linked.
  class Row
    attr_reader :label, :suggestion

    delegate :summary, :direction, :policy, :reasoning, :error?,
             :proposed_policy_name, :proposed_policy_description, to: :suggestion

    def initialize(panel, label, suggestion)
      @panel = panel
      @label = label
      @suggestion = suggestion
    end

    def unclassified?
      suggestion.nil?
    end

    def new_policy?
      suggestion.match == "new"
    end

    def css_class
      "ai-policy-suggestion-#{unclassified? ? 'unclassified' : suggestion.outcome}"
    end

    def vote_class
      direction == "for" ? "voted-aye" : "voted-no"
    end

    def agree_count
      panel.agree_count(suggestion)
    end

    def agreement?
      agree_count > 1
    end

    def linked_same_way?
      linked_vote.present? && PolicyDivision.vote_without_strong(linked_vote) == suggested_vote
    end

    def linked_other_way?
      linked_vote.present? && !linked_same_way?
    end

    private

    attr_reader :panel

    def linked_vote
      panel.linked_vote(suggestion)
    end

    def suggested_vote
      direction == "for" ? "aye" : "no"
    end
  end
end
