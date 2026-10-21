# frozen_string_literal: true

require "administrate/base_dashboard"

class AnnouncementDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    body: Field::Text,
    published: Field::Boolean,
    starts_at: Field::DateTime,
    ends_at: Field::DateTime,
    created_at: Field::DateTime,
    updated_at: Field::DateTime
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
    id
    body
    published
    starts_at
    ends_at
  ].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    id
    body
    published
    starts_at
    ends_at
    created_at
    updated_at
  ].freeze

  FORM_ATTRIBUTES = %i[
    body
    published
    starts_at
    ends_at
  ].freeze

  COLLECTION_FILTERS = {}.freeze

  def display_resource(announcement)
    "Announcement ##{announcement.id}"
  end
end
