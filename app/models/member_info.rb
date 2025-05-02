# frozen_string_literal: true

class MemberInfo < ApplicationRecord
  belongs_to :member, touch: true

  def self.update_all!
    rebellions = all_rebellion_counts
    tells = all_tells_counts
    votes_attended = all_votes_attended_counts
    votes_possible = all_votes_possible_counts
    aye_majority = all_aye_majority_counts

    Member.ids.each do |id|
      info = MemberInfo.find_or_initialize_by(member_id: id)
      info.update(
        rebellions: rebellions[id] || 0,
        tells: tells[id] || 0,
        votes_attended: votes_attended[id] || 0,
        votes_possible: votes_possible[id] || 0,
        aye_majority: aye_majority[id] || 0
      )
    end
  end

  def self.all_rebellion_counts
    Vote.rebellious.group("members.id").count
  end

  def self.all_tells_counts
    Vote.tells.group("votes.member_id").count
  end

  def self.all_votes_attended_counts
    Vote.group("votes.member_id").count
  end

  def self.all_ayes_counts
    Vote.ayes.group("votes.member_id").count
  end

  def self.all_noes_counts
    Vote.noes.group("votes.member_id").count
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
    Division.joins("INNER JOIN members ON divisions.house = members.house AND members.entered_house <= divisions.date AND divisions.date < members.left_house").group("members.id").count
  end
end
