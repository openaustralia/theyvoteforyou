# frozen_string_literal: true

module PeopleHelper
  # If this person has been a member of only one house then call them a "Senator" or a "Representative"
  # otherwise just call them "person"
  def person_type(person)
    if person.members.count > 1 && person.members.map(&:house).uniq.count > 1
      "person"
    else
      member_type(person.members.first.house)
    end
  end
end
