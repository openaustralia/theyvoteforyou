# frozen_string_literal: true

# This provides a cache for several distance measures between members
class MemberDistance < ApplicationRecord
  # TODO: Remove distance_a and nvotesabsent from schema as they are no longer used
  belongs_to :member1, class_name: "Member"
  belongs_to :member2, class_name: "Member"

  def agreement_fraction_without_absences
    1 - distance_b
  end

  def self.update_member(member1)
    Rails.logger.info "Updating distances for #{member1.name}..."
    # Find all members who overlap with this member
    members = Member.where(house: member1.house).where("left_house >= ?", member1.entered_house)
                    .where("entered_house <= ?", member1.left_house)
    # We're only populating half of the matrix
    members.where("id >= ?", member1.id).find_each do |member2|
      params = calculate_distances(member1, member2)
      # TODO: If distance_b is -1 then we don't even want a MemberDistance record. This would
      # allow us to remove further checks for distance_b != -1
      # Matrix is symmetric so we don't have to calculate twice
      MemberDistance.find_or_initialize_by(member1: member1, member2: member2).update(params)
      MemberDistance.find_or_initialize_by(member1: member2, member2: member1).update(params)
    end
  end

  def self.calculate_distances(member1, member2)
    r = Division
        .joins("INNER JOIN votes AS votes1 on votes1.division_id = divisions.id")
        .joins("INNER JOIN votes AS votes2 on votes2.division_id = divisions.id")
        .where(votes1: { member_id: member1.id })
        .where(votes2: { member_id: member2.id })
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
end
