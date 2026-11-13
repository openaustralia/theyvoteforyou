# frozen_string_literal: true

require "administrate/base_dashboard"

# Lists what admins have uploaded and how processing went. Read only: uploads are made on the
# upload page (Admin::IngestsController#new). An upload that failed is fixed by uploading a
# corrected file, or queued again as it is (Admin::IngestsController#requeue), not by editing the row.
class IngestDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    kind: Field::String,
    status: Field::String,
    user: Field::BelongsTo,
    original_filename: Field::String,
    records_saved: Field::Number,
    error: Field::Text,
    processed_at: Field::DateTime,
    created_at: Field::DateTime
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
    id
    kind
    status
    original_filename
    user
    records_saved
    created_at
  ].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    id
    kind
    status
    original_filename
    user
    records_saved
    error
    created_at
    processed_at
  ].freeze

  FORM_ATTRIBUTES = [].freeze

  COLLECTION_FILTERS = {}.freeze

  def display_resource(ingest)
    "#{ingest.kind} upload ##{ingest.id}"
  end
end
