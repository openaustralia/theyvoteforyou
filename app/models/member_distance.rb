# This provides a cache for several distance measures between members
class MemberDistance < ActiveRecord::Base
  self.table_name = "pw_cache_realreal_distance"
  belongs_to :member, foreign_key: :mp_id1
  belongs_to :member2, foreign_key: :mp_id2, class_name: "Member"

  def agreement_percentage
    (1 - distance_a) * 100
  end

  def agreement_percentage_without_abstentions
    (1 - distance_b) * 100
  end

  def self.calculate_nvotessame(member1, member2)
    # TODO Move knowledge of tells out of here. Shouldn't have to know about this to do this
    # kind of query
    Division
      .joins("LEFT JOIN pw_vote AS pw_vote1 on pw_vote1.division_id = pw_division.division_id")
      .joins("LEFT JOIN pw_vote AS pw_vote2 on pw_vote2.division_id = pw_division.division_id")
      .where("pw_vote1.mp_id = ?", member1.id)
      .where("pw_vote2.mp_id = ?", member2.id)
      .where("((pw_vote1.vote = 'aye' OR pw_vote1.vote = 'tellaye') AND (pw_vote2.vote = 'aye' OR pw_vote2.vote = 'tellaye')) OR ((pw_vote1.vote = 'no' OR pw_vote1.vote = 'tellno') AND (pw_vote2.vote = 'no' OR pw_vote2.vote = 'tellno'))")
      .count
  end

  def self.calculate_nvotesdiffer(member1, member2)
    Division
      .joins("LEFT JOIN pw_vote AS pw_vote1 on pw_vote1.division_id = pw_division.division_id")
      .joins("LEFT JOIN pw_vote AS pw_vote2 on pw_vote2.division_id = pw_division.division_id")
      .where("pw_vote1.mp_id = ?", member1.id)
      .where("pw_vote2.mp_id = ?", member2.id)
      .where("((pw_vote1.vote = 'aye' OR pw_vote1.vote = 'tellaye') AND (pw_vote2.vote = 'no' OR pw_vote2.vote = 'tellno')) OR ((pw_vote1.vote = 'no' OR pw_vote1.vote = 'tellno') AND (pw_vote2.vote = 'aye' OR pw_vote2.vote = 'tellaye'))")
      .count
  end

  # Count the number of times one of the two members is absent (but not both)
  def self.calculate_nvotesabsent(member1, member2)
    Division
      .joins("LEFT JOIN pw_vote AS pw_vote1 on pw_vote1.division_id = pw_division.division_id AND pw_vote1.mp_id = #{member1.id}")
      .joins("LEFT JOIN pw_vote AS pw_vote2 on pw_vote2.division_id = pw_division.division_id AND pw_vote2.mp_id = #{member2.id}")
      .where("(pw_vote1.vote IS NULL AND pw_vote2.vote IS NOT NULL) OR (pw_vote1.vote IS NOT NULL AND pw_vote2.vote IS NULL)")
      .count
  end

  def self.calculate_distance_a(same, diff, absent)
    Distance.distance_a(same, diff, absent)
  end

  def self.calculate_distance_b(same, diff)
    Distance.distance_b(same, diff)
  end
end
