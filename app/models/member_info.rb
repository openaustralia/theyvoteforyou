class MemberInfo < ActiveRecord::Base
  belongs_to :member, foreign_key: "mp_id"

  def self.update_all!
    rebellions = all_rebellion_counts
    tells = all_tells_counts
    votes_attended = all_votes_attended_counts
    votes_possible = all_votes_possible_counts
    aye_majority = all_aye_majority_counts

    Member.all.ids.each do |id|
      # TODO Give MemberInfo a primary key so that we can do this more sensibly
      MemberInfo.transaction do
        MemberInfo.where(mp_id: id).delete_all
        MemberInfo.create(mp_id: id,
          rebellions: rebellions[id] || 0, tells: tells[id] || 0,
          votes_attended: votes_attended[id] || 0, votes_possible: votes_possible[id] || 0,
          aye_majority: aye_majority[id] || 0)
      end
    end
  end

  def self.all_rebellion_counts
    Vote.rebellious.group("members.mp_id").count
  end

  def self.all_tells_counts
    Vote.tells.group("votes.mp_id").count
  end

  def self.all_votes_attended_counts
    Vote.all.group("votes.mp_id").count
  end

  def self.all_ayes_counts
    Vote.ayes.group("votes.mp_id").count
  end

  def self.all_noes_counts
    Vote.noes.group("votes.mp_id").count
  end

  def self.all_aye_majority_counts
    ayes = all_ayes_counts
    noes = all_noes_counts
    keys = (ayes.keys + noes.keys).uniq
    r = {}
    keys.each do |key|
      r[key] = (ayes[key] || 0) - (noes[key] || 0)
    end
    r
  end

  def self.all_votes_possible_counts
    Division.joins("INNER JOIN members ON pw_division.house = members.house AND members.entered_house <= pw_division.division_date AND pw_division.division_date < members.left_house").group("members.mp_id").count
  end
end
