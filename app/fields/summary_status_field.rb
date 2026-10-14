# frozen_string_literal: true

require "administrate/field/base"

# Whether a Division has a human-written summary yet (Division#edited?) and, if not, how many AI
# drafts are waiting for an editor to pick from. A draft counts under the same test as
# DivisionStaffStatus: no error and a title. The list loads the associations this reads in
# Admin::DivisionsController#scoped_resource, so it doesn't query once per row.
class SummaryStatusField < Administrate::Field::Base
  def self.searchable?
    false
  end

  def summarised?
    resource.edited?
  end

  def drafts_waiting
    resource.ai_division_summaries.count { |draft| draft.error.blank? && draft.title.present? }
  end

  # The badge's wording, which is also its test: "Not summarised yet" stands out, "Summarised" doesn't.
  def label
    return "Summarised" if summarised?

    "Not summarised yet"
  end

  def drafts_label
    "#{drafts_waiting} AI #{'draft'.pluralize(drafts_waiting)} waiting for review" if !summarised? && drafts_waiting.positive?
  end
end
