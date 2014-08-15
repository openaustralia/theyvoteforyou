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

  # TODO: Need to make this formula more clear
  def self.calc_dreammp_person_distance(nvotessame, nvotessamestrong, nvotesdiffer, nvotesdifferstrong,
    nvotesabsent, nvotesabsentstrong)
    # absents have low weighting, except where it is a strong vote
    strong_weight = 5.0
    absent_weight = 0.2
    weight = nvotessame + strong_weight * nvotessamestrong + nvotesdiffer + strong_weight * nvotesdifferstrong +
          absent_weight * nvotesabsent + strong_weight * nvotesabsentstrong

    score = nvotesdiffer + strong_weight * nvotesdifferstrong + absent_weight / 2 * nvotesabsent + strong_weight / 2 * nvotesabsentstrong
    if weight > 0
      score / weight
    else
      -1.0
    end
  end

  def self.calculate_distance_a(same, diff, absent)
    calc_dreammp_person_distance(same, 0, diff, 0, absent, 0)
  end

  def self.calculate_distance_b(same, diff)
    calculate_distance_a(same, diff, 0)
  end
end
