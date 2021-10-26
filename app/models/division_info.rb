# frozen_string_literal: true

class DivisionInfo < ApplicationRecord
  belongs_to :division

  # TODO: Fix duplication between this class and MemberInfo

  def majority
    aye_majority.abs
  end

  # a tie is 0.0. a unanimous vote is 1.0
  def majority_fraction
    turnout.positive? ? majority.to_f / turnout : 0
  end

  def self.update_all!
    rebellions = all_rebellion_counts
    tells = all_tells_counts
    turnout = all_turnout_counts
    possible_turnout = all_possible_turnout_counts
    aye_majority = all_aye_majority_counts

    Division.all.ids.each do |id|
      info = DivisionInfo.find_or_initialize_by(division_id: id)
      info.update(rebellions: rebellions[id] || 0, tells: tells[id] || 0,
                  turnout: turnout[id] || 0, possible_turnout: possible_turnout[id] || 0,
                  aye_majority: aye_majority[id] || 0)
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
    Division.joins("INNER JOIN members ON divisions.house = members.house AND members.entered_house <= divisions.date AND divisions.date < members.left_house").group("divisions.id").count
  end
end
