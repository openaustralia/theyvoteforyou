class DivisionInfo < ActiveRecord::Base
  self.table_name = "pw_cache_divinfo"

  belongs_to :division

  # TODO Fix duplication between this class and MemberInfo

  def self.update_all!
    rebellions = all_rebellion_counts
    tells = all_tells_counts
    turnout = all_turnout_counts
    possible_turnout = all_possible_turnout_counts
    aye_majority = all_aye_majority_counts

    Division.all.ids.each do |id|
      # TODO Give DivisionInfo a primary key so that we can do this more sensibly
      DivisionInfo.transaction do
        DivisionInfo.where(division_id: id).delete_all
        DivisionInfo.create(division_id: id,
          rebellions: rebellions[id] || 0, tells: tells[id] || 0,
          turnout: turnout[id] || 0, possible_turnout: possible_turnout[id] || 0,
          aye_majority: aye_majority[id] || 0)
      end
    end
  end

  def self.all_rebellion_counts
    Vote.rebellious.group("votes.division_id").count
  end

  def self.all_tells_counts
    Vote.tells.group("votes.division_id").count
  end

  def self.all_turnout_counts
    Vote.all.group("votes.division_id").count
  end

  def self.all_ayes_counts
    Vote.ayes.group("votes.division_id").count
  end

  def self.all_noes_counts
    Vote.noes.group("votes.division_id").count
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

  def self.all_possible_turnout_counts
    Division.joins("INNER JOIN members ON pw_division.house = members.house AND members.entered_house <= pw_division.division_date AND pw_division.division_date < members.left_house").group("pw_division.division_id").count
  end
end
