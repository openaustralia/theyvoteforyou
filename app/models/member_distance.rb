# frozen_string_literal: true

# This provides a cache for several distance measures between members
class MemberDistance < ApplicationRecord
  # TODO: Remove distance_a and nvotesabsent from schema as they are no longer used
  belongs_to :member1, class_name: "Member"
  belongs_to :member2, class_name: "Member"

  def agreement_fraction_without_absences
    1 - distance_b
  end

  def self.update_all!
    Member.all.find_each { |member| update_member(member) }
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
    result = {
      nvotessame: MemberDistance.calculate_nvotessame(member1.id, member2.id),
      nvotesdiffer: MemberDistance.calculate_nvotesdiffer(member1.id, member2.id)
    }
    result[:distance_b] = Distance.new(same: result[:nvotessame], differ: result[:nvotesdiffer]).distance
    result
  end

  def self.calculate_nvotessame(member1_id, member2_id)
    Division
      .joins("INNER JOIN votes AS votes1 on votes1.division_id = divisions.id")
      .joins("INNER JOIN votes AS votes2 on votes2.division_id = divisions.id")
      .where(votes1: { member_id: member1_id })
      .where(votes2: { member_id: member2_id })
      .where("(votes1.vote = 'aye' AND votes2.vote = 'aye') OR (votes1.vote = 'no' AND votes2.vote = 'no')")
      .count
  end

  def self.calculate_nvotesdiffer(member1_id, member2_id)
    Division
      .joins("INNER JOIN votes AS votes1 on votes1.division_id = divisions.id")
      .joins("INNER JOIN votes AS votes2 on votes2.division_id = divisions.id")
      .where(votes1: { member_id: member1_id })
      .where(votes2: { member_id: member2_id })
      .where("(votes1.vote = 'aye' AND votes2.vote = 'no') OR (votes1.vote = 'no' AND votes2.vote = 'aye')")
      .count
  end
end
