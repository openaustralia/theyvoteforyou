# frozen_string_literal: true

class WikiMotion < ApplicationRecord
  belongs_to :user
  belongs_to :division

  validates :title, :description, presence: true
  # ai_assisted is nullable on purpose: nil means "not recorded", which is not the same as "no AI used".
  validates :ai_model, presence: true, if: :ai_assisted?
  validates :ai_model, length: { maximum: 100 }

  before_validation :tidy_ai_model

  attr_writer :title, :description

  before_save :set_text_body, unless: :text_body
  after_create do
    alert_policy_watches
    # Don't reindex in tests when searchkick callbacks are disabled
    division.reindex if Searchkick.callbacks?
  end

  # Model names used on earlier summaries, for the form's autocomplete.
  def self.ai_models
    where.not(ai_model: nil).distinct.order(:ai_model).pluck(:ai_model)
  end

  def previous_edit
    division.wiki_motions.find_by("created_at < ?", created_at)
  end

  def title
    @title ||= text_body[/--- DIVISION TITLE ---(.*)--- MOTION EFFECT/m, 1]
  end

  def description
    @description ||= text_body[/--- MOTION EFFECT ---(.*)--- COMMENT/m, 1]
  end

  def previous_description
    if previous_edit
      previous_edit.description
    else
      division.original_motion
    end
  end

  def previous_title
    if previous_edit
      previous_edit.title
    else
      division.original_name
    end
  end

  private

  # A model name only makes sense when AI was used, and stray spaces would split one model into two suggestions.
  def tidy_ai_model
    self.ai_model = ai_assisted? ? ai_model.to_s.squish.presence : nil
  end

  def set_text_body
    self.text_body = <<~RECORD
            --- DIVISION TITLE ---
      #{'      '}
            #{title}
      #{'      '}
            --- MOTION EFFECT ---
      #{'      '}
            #{description}
      #{'      '}
            --- COMMENTS AND NOTES ---
      #{'      '}
            (put thoughts and notes for other researchers here)
    RECORD
  end

  def alert_policy_watches
    division.policies.each do |policy|
      policy.alert_watches(self)
    end
  end
end
