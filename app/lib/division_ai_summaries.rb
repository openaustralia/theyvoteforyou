# frozen_string_literal: true

# Assembles what the AI summary drafts panels (division show page, edit form) need: one Row per
# model DivisionSummarizer knows how to label, and what (if anything) it drafted for this
# division. It decides nothing about summarising itself - that's DivisionSummarizer writing
# AiDivisionSummary records - it only presents those records for a human to review.
class DivisionAiSummaries
  include Enumerable

  def initialize(division)
    @division = division
  end

  def each(&)
    rows.each(&)
  end

  private

  attr_reader :division

  def known_models
    DivisionPolicyClassifier::MODEL_LABELS
  end

  # Only models the panel can label: a summary left over from a model id since retired from
  # MODEL_LABELS shouldn't appear as a mystery row.
  def summaries
    @summaries ||= division.ai_division_summaries.index_by(&:model).slice(*known_models.keys)
  end

  def rows
    @rows ||= known_models.map { |model_id, label| Row.new(label, summaries[model_id]) }
  end

  # One model's row: its label, and what it drafted (if anything).
  class Row
    attr_reader :label, :summary

    delegate :title, :description, :error, to: :summary

    def initialize(label, summary)
      @label = label
      @summary = summary
    end

    def drafted?
      summary.present?
    end

    def error?
      drafted? && error.present?
    end

    # A stable, unique DOM id for this row's nav-tab pane.
    def tab_id
      "ai-summary-tab-#{label.parameterize}"
    end
  end
end
