# frozen_string_literal: true

# Records what one AI model wrote as a plain-language title and description for a Division -
# a draft for a human to review via the existing WikiMotion edit form, not a real summary.
# There is one row per division and model, so a new draft from the same model replaces the old.
class AiDivisionSummary < ApplicationRecord
  belongs_to :division
  # The upload this draft arrived in, when it was written elsewhere rather than by the pipeline here.
  belongs_to :ingest, optional: true

  validates :model, presence: true
end
