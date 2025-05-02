# frozen_string_literal: true

FactoryBot.define do
  factory :office do
    # TODO: Get rid of dept and responsibility in the schema
    dept { "" }
    responsibility { "" }
    position { "Minister for ponies" }
    # TODO: Make person_id null: false in the schema
    # We are pretending this has already been done here
    person
  end
end
