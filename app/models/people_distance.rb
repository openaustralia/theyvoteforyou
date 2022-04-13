# frozen_string_literal: true

class PeopleDistance < ApplicationRecord
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
