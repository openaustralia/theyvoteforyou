# frozen_string_literal: true

require "administrate/base_dashboard"

# Only here so a division's page can list the AI policy drafts made for it (DivisionDashboard).
# There's no admin route for these: they're drafts for a human to review, not records to edit.
class AiPolicySuggestionDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    division: Field::BelongsTo,
    policy: Field::BelongsTo,
    id: Field::Number,
    model: Field::String,
    match: Field::String,
    direction: Field::String,
    proposed_policy_name: Field::String,
    proposed_policy_description: Field::Text,
    reasoning: Field::Text,
    error: Field::Text,
    created_at: Field::DateTime
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
    model
    match
    policy
    proposed_policy_name
    direction
    error
  ].freeze

  SHOW_PAGE_ATTRIBUTES = ATTRIBUTE_TYPES.keys.freeze

  FORM_ATTRIBUTES = [].freeze

  COLLECTION_FILTERS = {}.freeze
end
