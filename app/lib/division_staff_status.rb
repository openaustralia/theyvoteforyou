# frozen_string_literal: true

# What staff want to see at a glance about a Division on the list pages: has it been summarised,
# does it have AI summary drafts, is it linked to a policy, and does it have AI policy suggestions.
# Works from the already-loaded associations, so the list should preload ai_division_summaries,
# ai_policy_suggestions and policy_divisions to avoid N+1 queries. Errored AI rows don't count as
# drafts, as they hold nothing for a human to review.
class DivisionStaffStatus
  include Enumerable

  Item = Struct.new(:label, :done, :title) do
    alias_method :done?, :done
  end

  def initialize(division)
    @division = division
  end

  def each(&)
    items.each(&)
  end

  private

  attr_reader :division

  def items
    [
      Item.new("Summary", division.edited?, "A human-written summary has been published"),
      Item.new("AI summary drafts", ai_summary_drafts?, "AI summary drafts are waiting for review"),
      Item.new("Policy", division.policy_divisions.any?, "Linked to at least one policy"),
      Item.new("AI policy drafts", ai_policy_drafts?, "AI policy suggestions are waiting for review")
    ]
  end

  def ai_summary_drafts?
    division.ai_division_summaries.any? { |s| s.error.blank? && s.title.present? }
  end

  def ai_policy_drafts?
    division.ai_policy_suggestions.any? { |s| !s.error? }
  end
end
