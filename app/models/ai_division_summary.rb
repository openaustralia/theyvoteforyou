# frozen_string_literal: true

# Records what one AI model wrote as a plain-language title and description for a Division -
# a draft for a human to review via the existing WikiMotion edit form, not a real summary (see
# DivisionSummarizer, WikiMotion).
class AiDivisionSummary < ApplicationRecord
  belongs_to :division

  validates :model, presence: true

  def self.create_from_result!(division, result)
    create!(
      division: division,
      model: result.model,
      title: result.title,
      description: result.description,
      raw_response: result.raw,
      error: result.error
    )
  end
end
