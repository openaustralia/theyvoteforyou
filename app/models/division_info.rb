class DivisionInfo < ActiveRecord::Base
  self.table_name = "pw_cache_divinfo"

  belongs_to :division

  def self.all_rebellion_counts
    Vote.rebellious.group("pw_vote.division_id").count
  end

  def self.all_tells_counts
    Vote.tells.group("pw_vote.division_id").count
  end

  def self.all_votes_attended_counts
    Vote.all.group("pw_vote.division_id").count
  end

  def self.all_ayes_counts
    Vote.ayes.group("pw_vote.division_id").count
  end

  def self.all_noes_counts
    Vote.noes.group("pw_vote.division_id").count
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
    Division.joins("INNER JOIN pw_mp ON pw_division.house = pw_mp.house AND pw_mp.entered_house <= pw_division.division_date AND pw_division.division_date < pw_mp.left_house").group("pw_division.division_id").count
  end
end
