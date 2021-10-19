# frozen_string_literal: true

class CreatePeople < ActiveRecord::Migration
  def change
    create_table :people, &:timestamps
    # Create all the people
    Person.reset_column_information
    Member.group(:person_id).pluck(:person_id).each do |person_id|
      Person.create!(id: person_id)
    end
  end
end
