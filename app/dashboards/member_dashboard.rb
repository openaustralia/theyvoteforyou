# frozen_string_literal: true

require "administrate/base_dashboard"

# A read-only list of members of the House of Representatives and the Senate, for checking what
# the data loader brought in. Members are loaded from ParlParse XML (DataLoader::Members), so
# changes belong there, not on this screen.
class MemberDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    first_name: Field::String,
    last_name: Field::String,
    house: Field::String,
    constituency: Field::String,
    party: Field::String,
    entered_house: Field::Date,
    entered_reason: Field::String,
    left_house: Field::Date,
    left_reason: Field::String,
    person_id: Field::Number,
    gid: Field::String,
    created_at: Field::DateTime,
    updated_at: Field::DateTime
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
    id
    first_name
    last_name
    house
    constituency
    party
    entered_house
    left_house
  ].freeze

  SHOW_PAGE_ATTRIBUTES = ATTRIBUTE_TYPES.keys.freeze

  FORM_ATTRIBUTES = [].freeze

  COLLECTION_FILTERS = {
    current: ->(resources) { resources.current },
    senate: ->(resources) { resources.in_house("senate") },
    representatives: ->(resources) { resources.in_house("representatives") }
  }.freeze

  def display_resource(member)
    "#{member.first_name} #{member.last_name} (#{member.house})"
  end
end
