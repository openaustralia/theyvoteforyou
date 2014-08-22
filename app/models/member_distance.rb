# This provides a cache for several distance measures between members
class MemberDistance < ActiveRecord::Base
  belongs_to :member1, foreign_key: :mp_id1, class_name: "Member"
  belongs_to :member2, foreign_key: :mp_id2, class_name: "Member"

  before_save :update_cache_values!

  def agreement_percentage
    (1 - distance_a) * 100
  end

  def agreement_percentage_without_abstentions
    (1 - distance_b) * 100
  end

  def self.update_all!
    Member.all.find_each do |member1|
      puts "Updating distances for #{member1.name}..."
      # Find all members who overlap with this member
      members = Member.where(house: member1.house).where("left_house >= ?", member1.entered_house).
        where("entered_house <= ?", member1.left_house)
      # We're only populating half of the matrix
      members.where("mp_id >= ?", member1.mp_id).each do |member2|
        # Do something less icky when MemberDistance has a primary key
        MemberDistance.transaction do
          MemberDistance.where(member1: member1, member2: member2).delete_all
          MemberDistance.create(member1: member1, member2: member2)
        end
      end
    end
  end

  def update_cache_values!
    self.nvotessame = MemberDistance.calculate_nvotessame(member1, member2)
    self.nvotesdiffer = MemberDistance.calculate_nvotesdiffer(member1, member2)
    self.nvotesabsent = MemberDistance.calculate_nvotesabsent(member1, member2)
    self.distance_a = Distance.distance_a(nvotessame, nvotesdiffer, nvotesabsent)
    self.distance_b = Distance.distance_b(nvotessame, nvotesdiffer)
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
  # someone is absent only if they could vote on a division but didn't
  def self.calculate_nvotesabsent(member1, member2)
    Division
      .where("pw_division.division_date >= ?", member1.entered_house)
      .where("pw_division.division_date <= ?", member1.left_house)
      .where("pw_division.division_date >= ?", member2.entered_house)
      .where("pw_division.division_date <= ?", member2.left_house)
      .joins("LEFT JOIN pw_vote AS pw_vote1 on pw_vote1.division_id = pw_division.division_id AND pw_vote1.mp_id = #{member1.id}")
      .joins("LEFT JOIN pw_vote AS pw_vote2 on pw_vote2.division_id = pw_division.division_id AND pw_vote2.mp_id = #{member2.id}")
      .where("(pw_vote1.vote IS NULL AND pw_vote2.vote IS NOT NULL) OR (pw_vote1.vote IS NOT NULL AND pw_vote2.vote IS NULL)")
      .count
  end
end
