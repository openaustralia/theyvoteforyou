# frozen_string_literal: true

# A message staff publish to show as a bar across the top of the site. The body is HTML, which is sanitised when shown.
class Announcement < ApplicationRecord
  validates :body, presence: true
  validate :ends_after_it_starts

  # Published, and inside its optional start and end times
  scope :live, lambda { |at = Time.current|
    where(published: true)
      .where("starts_at IS NULL OR starts_at <= ?", at)
      .where("ends_at IS NULL OR ends_at > ?", at)
  }

  # Only one announcement shows at a time: the newest live one
  def self.current
    live.order(created_at: :desc, id: :desc).first
  end

  # Remembered in a cookie when someone dismisses the bar. It changes when the announcement is edited, so an edited
  # announcement shows again to people who dismissed the old text.
  def dismissal_key
    "#{id}-#{updated_at.strftime('%s%6N')}"
  end

  private

  def ends_after_it_starts
    return if starts_at.blank? || ends_at.blank? || ends_at > starts_at

    errors.add(:ends_at, "must be after the start")
  end
end
