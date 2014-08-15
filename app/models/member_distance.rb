# This provides a cache for several distance measures between members
class MemberDistance < ActiveRecord::Base
  self.table_name = "pw_cache_realreal_distance"
  belongs_to :member, foreign_key: :mp_id1
  belongs_to :member2, foreign_key: :mp_id2, class_name: "Member"

  # # TODO: Can we do this as an association?
  # def member2
  #   Member.find mp_id2
  # end

  def agreement_percentage
    (1 - distance_a) * 100
  end

  def agreement_percentage_without_abstentions
    (1 - distance_b) * 100
  end

  def self.calculate_nvotessame(member1, member2)
    # TODO This doesn't take into account tellers yet
    Division
      .joins("LEFT JOIN pw_vote AS pw_vote1 on pw_vote1.division_id = pw_division.division_id")
      .joins("LEFT JOIN pw_vote AS pw_vote2 on pw_vote2.division_id = pw_division.division_id")
      .where("pw_vote1.mp_id = ?", member1.id)
      .where("pw_vote2.mp_id = ?", member2.id)
      .where("pw_vote1.vote = pw_vote2.vote")
      .count
  end
end
