# frozen_string_literal: true

# Records what one AI model picked for a Division when asked to classify it against our Policies -
# either an existing Policy match or a proposed new one - along with its reasoning. A draft for a
# human to review, not a real classification (see DivisionPolicyClassifier, PolicyDivision).
class AiPolicySuggestion < ApplicationRecord
  belongs_to :division
  belongs_to :policy, optional: true

  validates :model, presence: true
  validates :match, inclusion: { in: %w[existing new] }, allow_nil: true
  validates :direction, inclusion: { in: %w[for against] }, allow_nil: true

  # Overwrites any row already held for this division and model. There's a unique index on the
  # pair, so a plain create raises once a failed attempt has left an errored row behind, which is
  # exactly when a retry needs to write.
  def self.save_from_result!(division, result)
    suggestion = find_or_initialize_by(division: division, model: result.model)
    suggestion.update!(
      policy: result.policy,
      match: result.match,
      direction: result.direction,
      proposed_policy_name: result.new_policy_name,
      proposed_policy_description: result.new_policy_description,
      reasoning: result.reasoning,
      raw_response: result.raw,
      error: result.error
    )
    suggestion
  end

  # True whenever #summary describes an error rather than an actual classification, whether or
  # not the error column itself is set (a nil match/direction is a malformed response, not
  # something DivisionPolicyClassifier flagged as an error at the time).
  def error?
    error.present? || match.nil? || direction.nil?
  end

  def summary
    return "Error: #{error}" if error
    return "Error: model response was missing match/direction" if match.nil? || direction.nil?

    subject = match == "existing" ? existing_policy_subject : "new policy I propose"
    "#{direction == 'for' ? 'For' : 'Against'} #{subject}"
  end

  private

  # Deleting a Policy nullifies policy_id on its suggestions (Policy has_many :ai_policy_suggestions,
  # dependent: :nullify), so once it's gone there's no id left to name either.
  def existing_policy_subject
    return "a policy that has since been deleted" unless policy

    "policy #{policy_id} (#{policy.name})"
  end
end
