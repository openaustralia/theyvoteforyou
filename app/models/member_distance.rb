# frozen_string_literal: true

# This provides a cache for several distance measures between members
class MemberDistance < ApplicationRecord
  # TODO: Remove distance_b from database schema
  belongs_to :member1, class_name: "Member"
  belongs_to :member2, class_name: "Member"

  def agreement_fraction
    1 - distance_a
  end

  def self.update_all!
    Member.all.find_each do |member1|
      Rails.logger.info "Updating distances for #{member1.name}..."
      # Find all members who overlap with this member
      members = Member.where(house: member1.house).where("left_house >= ?", member1.entered_house)
                      .where("entered_house <= ?", member1.left_house)
      # We're only populating half of the matrix
      members.where("id >= ?", member1.id).find_each do |member2|
        params = calculate_distances(member1, member2)
        # Matrix is symmetric so we don't have to calculate twice
        MemberDistance.find_or_initialize_by(member1: member1, member2: member2).update(params)
        MemberDistance.find_or_initialize_by(member1: member2, member2: member1).update(params)
      end
    end
  end

  def self.calculate_distances(member1, member2)
    m1_id = member1.id
    m1_entered_house = member1.entered_house
    m1_left_house = member2.left_house
    m2_id = member2.id
    m2_entered_house = member2.entered_house
    m2_left_house = member2.left_house
    result = {
      nvotessame: MemberDistance.calculate_nvotessame(m1_id, m2_id),
      nvotesdiffer: MemberDistance.calculate_nvotesdiffer(m1_id, m2_id),
      nvotesabsent: MemberDistance.calculate_nvotesabsent(m1_id, m1_entered_house, m1_left_house, m2_id, m2_entered_house, m2_left_house)
    }
    result[:distance_a] = Distance.new(same: result[:nvotessame], differ: result[:nvotesdiffer], absent: result[:nvotesabsent]).distance
    result
  end

  def self.calculate_nvotessame(member1_id, member2_id)
    # TODO: Move knowledge of tells out of here. Shouldn't have to know about this to do this
    # kind of query
    # Division
    #   .joins("LEFT JOIN votes AS votes1 on votes1.division_id = divisions.id")
    #   .joins("LEFT JOIN votes AS votes2 on votes2.division_id = divisions.id")
    #   .where("votes1.member_id = ?", member1_id)
    #   .where("votes2.member_id = ?", member2_id)
    #   .where("(votes1.vote = 'aye' AND votes2.vote = 'aye') OR (votes1.vote = 'no' AND votes2.vote = 'no')")
    #   .count

    nvs_sql = %{
SELECT
  COUNT(*)
FROM
  divisions
INNER JOIN
  votes AS votes1 on votes1.division_id = divisions.id
LEFT JOIN
  votes AS votes2 on votes2.division_id = divisions.id
WHERE
  (votes1.member_id = #{ActiveRecord::Base.sanitize member1_id}) AND
  (votes2.member_id = #{ActiveRecord::Base.sanitize member2_id}) AND
  ((votes1.vote = 'aye' AND votes2.vote = 'aye') OR
   (votes1.vote = 'no' AND votes2.vote = 'no'))
}
    ActiveRecord::Base.connection.execute(nvs_sql).first.first
  end

  def self.calculate_nvotesdiffer(member1_id, member2_id)
    # Division
    #   .joins("LEFT JOIN votes AS votes1 on votes1.division_id = divisions.id")
    #   .joins("LEFT JOIN votes AS votes2 on votes2.division_id = divisions.id")
    #   .where("votes1.member_id = ?", member1_id)
    #   .where("votes2.member_id = ?", member2_id)
    #   .where("(votes1.vote = 'aye' AND votes2.vote = 'no') OR (votes1.vote = 'no' AND votes2.vote = 'aye')")
    #   .count

    nvd_sql = %{
SELECT
  COUNT(*)
FROM
  divisions
LEFT JOIN
  votes AS votes1 on votes1.division_id = divisions.id
LEFT JOIN
  votes AS votes2 on votes2.division_id = divisions.id
WHERE
  (votes1.member_id = #{ActiveRecord::Base.sanitize member1_id}) AND
  (votes2.member_id = #{ActiveRecord::Base.sanitize member2_id}) AND
  ((votes1.vote = 'aye' AND votes2.vote = 'no') OR
   (votes1.vote = 'no' AND votes2.vote = 'aye'))
}

    ActiveRecord::Base.connection.execute(nvd_sql).first.first
  end

  # Count the number of times one of the two members is absent (but not both)
  # someone is absent only if they could vote on a division but didn't
  def self.calculate_nvotesabsent(member1_id, member1_entered_house, member1_left_house, member2_id, member2_entered_house, member2_left_house)
    # Division
    #   .where("divisions.date >= ?", member1_entered_house)
    #   .where("divisions.date <= ?", member1_left_house)
    #   .where("divisions.date >= ?", member2_entered_house)
    #   .where("divisions.date <= ?", member2_left_house)
    #   .joins("LEFT JOIN votes AS votes1 on votes1.division_id = divisions.id AND votes1.member_id = #{member1_id}")
    #   .joins("LEFT JOIN votes AS votes2 on votes2.division_id = divisions.id AND votes2.member_id = #{member2_id}")
    #   .where("(votes1.vote IS NULL AND votes2.vote IS NOT NULL) OR (votes1.vote IS NOT NULL AND votes2.vote IS NULL)")
    #   .count

    nva_sql = %{
SELECT
  COUNT(*)
FROM
  divisions
LEFT JOIN
  votes AS votes1 on votes1.division_id = divisions.id AND votes1.member_id = #{ActiveRecord::Base.sanitize member1_id}
LEFT JOIN
  votes AS votes2 on votes2.division_id = divisions.id AND votes2.member_id = #{ActiveRecord::Base.sanitize member2_id}
WHERE
  (divisions.date >= #{ActiveRecord::Base.sanitize member1_entered_house}) AND (divisions.date <= #{ActiveRecord::Base.sanitize member1_left_house}) AND
  (divisions.date >= #{ActiveRecord::Base.sanitize member2_entered_house}) AND (divisions.date <= #{ActiveRecord::Base.sanitize member2_left_house}) AND
  ((votes1.vote IS NULL AND votes2.vote IS NOT NULL) OR (votes1.vote IS NOT NULL AND votes2.vote IS NULL))
}

    ActiveRecord::Base.connection.execute(nva_sql).first.first
  end
end
