# frozen_string_literal: true

class PeopleDistance < ApplicationRecord
  belongs_to :person1, class_name: "Person"
  belongs_to :person2, class_name: "Person"

  def agreement_fraction_without_absences
    1 - distance_b
  end

  def total_votes
    nvotessame + nvotesdiffer
  end

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

  def self.calculate_distances(person1, person2)
    r = Division
        .joins("INNER JOIN votes AS votes1 on votes1.division_id = divisions.id")
        .joins("INNER JOIN votes AS votes2 on votes2.division_id = divisions.id")
        .joins("INNER JOIN members AS members1 on members1.id = votes1.member_id")
        .joins("INNER JOIN members AS members2 on members2.id = votes2.member_id")
        .where(members1: { person_id: person1.id })
        .where(members2: { person_id: person2.id })
        .group("votes1.vote = votes2.vote")
        .count
    same = r[1] || 0
    differ = r[0] || 0
    {
      nvotessame: same,
      nvotesdiffer: differ,
      distance_b: Distance.new(same: same, differ: differ).distance
    }
  end

  # Divisions where the two people voted differently
  def divisions_different
    Division
      .joins("INNER JOIN votes AS votes1 on votes1.division_id = divisions.id")
      .joins("INNER JOIN votes AS votes2 on votes2.division_id = divisions.id")
      .joins("INNER JOIN members AS members1 on members1.id = votes1.member_id")
      .joins("INNER JOIN members AS members2 on members2.id = votes2.member_id")
      .where(members1: { person_id: person1_id })
      .where(members2: { person_id: person2_id })
      .where("votes1.vote != votes2.vote")
  end

  # Divisions where the two people voted the same
  def divisions_same
    Division
      .joins("INNER JOIN votes AS votes1 on votes1.division_id = divisions.id")
      .joins("INNER JOIN votes AS votes2 on votes2.division_id = divisions.id")
      .joins("INNER JOIN members AS members1 on members1.id = votes1.member_id")
      .joins("INNER JOIN members AS members2 on members2.id = votes2.member_id")
      .where(members1: { person_id: person1_id })
      .where(members2: { person_id: person2_id })
      .where("votes1.vote = votes2.vote")
  end
end
