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

  def self.create_from_result!(division, result)
    create!(
      division: division,
      policy: result.policy,
      model: result.model,
      match: result.match,
      direction: result.direction,
      proposed_policy_name: result.new_policy_name,
      proposed_policy_description: result.new_policy_description,
      reasoning: result.reasoning,
      raw_response: result.raw,
      error: result.error
    )
  end

  def summary
    return "Error: #{error}" if error
    return "Error: model response was missing match/direction" if match.nil? || direction.nil?

    subject = match == "existing" ? existing_policy_subject : "new policy I propose"
    "#{direction == 'for' ? 'For' : 'Against'} #{subject}"
  end

  private

  # policy can be nil if the matched Policy has since been deleted
  def existing_policy_subject
    policy ? "policy #{policy_id} (#{policy.name})" : "policy #{policy_id}"
  end
end
