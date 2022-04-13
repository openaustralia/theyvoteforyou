# frozen_string_literal: true

class PeopleDistance < ApplicationRecord
  belongs_to :person1, class_name: "Person"
  belongs_to :person2, class_name: "Person"

  def self.update_person(person1)
    # We're only populating half of the matrix
    person1.overlapping_people.select { |p| p.id >= person1.id }.each do |person2|
      params = calculate_distances(person1, person2)
      # TODO: If distance_b is -1 then we don't even want a PeopleDistance record. This would
      # allow us to remove further checks for distance_b != -1
      # Matrix is symmetric so we don't have to calculate twice
      PeopleDistance.find_or_initialize_by(person1: person1, person2: person2).update!(params)
      PeopleDistance.find_or_initialize_by(person1: person2, person2: person1).update!(params)
    end
  end

  # This currently depends on the MemberDistance cache being up to date
  def self.calculate_distances(person1, person2)
    nvotessame = 0
    nvotesdiffer = 0
    person1.members.each do |member1|
      person2.members.each do |member2|
        d = MemberDistance.find_by(member1: member1, member2: member2)
        if d
          nvotessame += d.nvotessame
          nvotesdiffer += d.nvotesdiffer
        end
      end
    end
    {
      nvotessame: nvotessame,
      nvotesdiffer: nvotesdiffer,
      distance_b: Distance.new(same: nvotessame, differ: nvotesdiffer).distance
    }
  end
end
