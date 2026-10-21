# frozen_string_literal: true

require "administrate/base_dashboard"

# Divisions are imported from Hansard (see DataLoader), so editing or deleting one here changes
# imported data. Votes and whips are left off the screens: a division has hundreds of each, and
# Administrate would load every one to fill a form. Titles and descriptions normally go through
# the WikiMotion edit form, not this screen.
class DivisionDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    summary_status: SummaryStatusField,
    policies: Field::HasMany,
    ai_policy_suggestions: Field::HasMany,
    id: Field::Number,
    date: Field::Date,
    number: Field::Number,
    house: Field::Select.with_options(searchable: false, collection: -> { House.australian }),
    # A String field, not Text, because Administrate's search box only searches String fields. Name is
    # never null, unlike clock_time, so a filter or a search can't drop divisions that lack a clock time.
    name: Field::String,
    source_url: Field::Text,
    debate_url: Field::Text,
    motion: Field::Text,
    clock_time: Field::String,
    debate_gid: Field::Text,
    created_at: Field::DateTime,
    updated_at: Field::DateTime
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
    id
    house
    date
    number
    name
    summary_status
  ].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    id
    house
    date
    number
    clock_time
    summary_status
    name
    motion
    source_url
    debate_url
    debate_gid
    policies
    ai_policy_suggestions
    created_at
    updated_at
  ].freeze

  FORM_ATTRIBUTES = %i[
    house
    date
    number
    clock_time
    name
    motion
    source_url
    debate_url
    debate_gid
  ].freeze

  # Typed into the search box, and linked from the filter rows above the list
  # (admin/divisions/index.html.erb). A summary is a WikiMotion (Division#edited?). A draft waiting
  # is an AI summary with no error and a title, the same test as DivisionStaffStatus. They use
  # EXISTS rather than a join, so they combine with each other and with the search.
  HAS_SUMMARY = "EXISTS (SELECT 1 FROM wiki_motions WHERE wiki_motions.division_id = divisions.id)"
  HAS_DRAFT = "EXISTS (SELECT 1 FROM ai_division_summaries WHERE ai_division_summaries.division_id = divisions.id " \
              "AND ai_division_summaries.error IS NULL AND ai_division_summaries.title IS NOT NULL)"

  COLLECTION_FILTERS = {
    representatives: ->(resources) { resources.where(house: "representatives") },
    senate: ->(resources) { resources.where(house: "senate") },
    summarised: ->(resources) { resources.where(HAS_SUMMARY) },
    unsummarised: ->(resources) { resources.where.not(HAS_SUMMARY) },
    drafts_waiting: ->(resources) { resources.where.not(HAS_SUMMARY).where(HAS_DRAFT) }
  }.freeze

  def display_resource(division)
    "#{division.house} division #{division.date} ##{division.number}"
  end
end
