# frozen_string_literal: true

# Records what one AI model wrote as a plain-language title and description for a Division -
# a draft for a human to review via the existing WikiMotion edit form, not a real summary (see
# DivisionSummarizer, WikiMotion).
class AiDivisionSummary < ApplicationRecord
  belongs_to :division

  validates :model, presence: true

  # Overwrites any row already held for this division and model. There's a unique index on the
  # pair, so a plain create raises once a failed attempt has left an errored row behind, which is
  # exactly when a retry needs to write.
  def self.save_from_result!(division, result)
    summary = find_or_initialize_by(division: division, model: result.model)
    summary.update!(
      title: result.title,
      description: result.description,
      raw_response: result.raw,
      error: result.error
    )
    summary
  end
end
